import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mock user for testing UI without Firebase
  bool _isMockMode = true;
  User? _mockUser;
  UserModel? _mockUserProfile;

  AuthService() {
    if (_isMockMode) {
      // Create mock user for testing
      _mockUser = User(
        uid: 'mock-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      _mockUserProfile = UserModel(
        id: 'mock-user-id',
        username: 'terminal_user',
        email: 'test@example.com',
        bio: 'Terminal enthusiast',
        terminalColor: 'green',
        terminalTheme: 'dark',
        terminalFontSize: 14.0,
        terminalSound: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now(),
      );
    }
  }

  // Get current user
  User? get currentUser => _isMockMode ? _mockUser : _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    if (_isMockMode) {
      // Return a mock stream with our mock user
      return Stream.value(_mockUser);
    }
    return _auth.authStateChanges();
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    if (_isMockMode) {
      // Mock successful sign in
      await Future.delayed(const Duration(milliseconds: 500));
      return Future.value(null); // Mock credential
    }
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String username) async {
    if (_isMockMode) {
      // Mock successful sign up
      await Future.delayed(const Duration(milliseconds: 500));
      return Future.value(null); // Mock credential
    }
    try {
      // Create user authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _createUserProfile(userCredential.user!.uid, username, email);

      return userCredential;
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(
      String userId, String username, String email) async {
    await _firestore.collection('users').doc(userId).set({
      'username': username,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'bio': 'Terminal user',
      'terminalColor': 'green',
    });
  }

  // Sign out
  Future<void> signOut() async {
    if (_isMockMode) {
      // Mock sign out
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }
    await _auth.signOut();
  }

  // Get user profile data
  Future<UserModel> getUserProfile(String userId) async {
    if (_isMockMode) {
      // Return mock profile
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockUserProfile!;
    }
    
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!, userId);
      } else {
        // Create a new profile if it doesn't exist
        final newUser = UserModel(
          id: userId,
          username: currentUser?.displayName ?? 'user',
          email: currentUser?.email ?? '',
          bio: 'Terminal user',
          terminalColor: 'green',
          terminalTheme: 'dark',
          terminalFontSize: 14.0,
          terminalSound: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        await _firestore.collection('users').doc(userId).set(newUser.toJson());
        return newUser;
      }
    } catch (e) {
      print('Error getting user profile: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    if (_isMockMode) {
      // Update mock profile
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (data.containsKey('terminalColor')) {
        _mockUserProfile = _mockUserProfile!.copyWith(
          terminalColor: data['terminalColor']
        );
      }
      
      if (data.containsKey('bio')) {
        _mockUserProfile = _mockUserProfile!.copyWith(
          bio: data['bio']
        );
      }
      
      if (data.containsKey('terminalTheme')) {
        _mockUserProfile = _mockUserProfile!.copyWith(
          terminalTheme: data['terminalTheme']
        );
      }
      
      if (data.containsKey('terminalFontSize')) {
        _mockUserProfile = _mockUserProfile!.copyWith(
          terminalFontSize: data['terminalFontSize'].toDouble()
        );
      }
      
      if (data.containsKey('terminalSound')) {
        _mockUserProfile = _mockUserProfile!.copyWith(
          terminalSound: data['terminalSound'] == 'on'
        );
      }
      
      return;
    }
    
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Check if username exists
  Future<bool> usernameExists(String username) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }
  
  // Get all users
  Future<QuerySnapshot> getAllUsers() async {
    return await _firestore.collection('users').get();
  }

  // Mock class for User to avoid Firebase dependency during testing
  class User {
    final String uid;
    final String? email;
    final String? displayName;
    
    User({required this.uid, this.email, this.displayName});
  }

  // Mock class for UserCredential to avoid Firebase dependency during testing
  class UserCredential {
    final User? user;
    
    UserCredential({this.user});
  }

  // Mock class for FieldValue to avoid Firebase dependency during testing
  class FieldValue {
    static FieldValue serverTimestamp() {
      return FieldValue();
    }
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String bio;
  final String terminalColor;
  final String terminalTheme;
  final double terminalFontSize;
  final bool terminalSound;
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.bio,
    required this.terminalColor,
    required this.terminalTheme,
    required this.terminalFontSize,
    required this.terminalSound,
    required this.createdAt,
    required this.lastActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      username: json['username'],
      email: json['email'],
      bio: json['bio'],
      terminalColor: json['terminalColor'],
      terminalTheme: json['terminalTheme'],
      terminalFontSize: json['terminalFontSize'].toDouble(),
      terminalSound: json['terminalSound'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastActive: (json['lastActive'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'bio': bio,
      'terminalColor': terminalColor,
      'terminalTheme': terminalTheme,
      'terminalFontSize': terminalFontSize,
      'terminalSound': terminalSound,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  UserModel copyWith({
    String? terminalColor,
    String? bio,
    String? terminalTheme,
    double? terminalFontSize,
    bool? terminalSound,
  }) {
    return UserModel(
      id: id,
      username: username,
      email: email,
      bio: bio ?? this.bio,
      terminalColor: terminalColor ?? this.terminalColor,
      terminalTheme: terminalTheme ?? this.terminalTheme,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      terminalSound: terminalSound ?? this.terminalSound,
      createdAt: createdAt,
      lastActive: lastActive,
    );
  }
}
