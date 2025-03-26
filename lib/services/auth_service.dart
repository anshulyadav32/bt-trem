import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock class for User to avoid Firebase dependency during testing
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;
  
  MockUser({required this.uid, this.email, this.displayName});
}

// Mock class for UserCredential to avoid Firebase dependency during testing
class MockUserCredential {
  final MockUser? user;
  
  MockUserCredential({this.user});
}

class AuthService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  
  // Use mock mode when Firebase is unavailable (on Windows) or for testing
  final bool _isMockMode;
  MockUser? _mockUser;
  UserModel? _mockUserProfile;

  AuthService({bool useFirebase = false}) : 
    _isMockMode = !useFirebase,
    _auth = useFirebase ? FirebaseAuth.instance : null,
    _firestore = useFirebase ? FirebaseFirestore.instance : null {
    if (_isMockMode) {
      // Create mock user for testing
      _mockUser = MockUser(
        uid: 'mock-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      // Create mock user profile
      _mockUserProfile = UserModel(
        id: 'mock-user-id',
        username: 'test_user',
        email: 'test@example.com',
        bio: 'This is a mock user for testing',
        terminalColor: '#32a852',
        terminalTheme: 'dark',
        terminalFontSize: 14.0,
        terminalSound: true,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
    }
  }

  // Get current user
  User? get currentUser => _isMockMode ? (_mockUser as User?) : _auth?.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    if (_isMockMode) {
      // Return a mock stream with our mock user
      return Stream.value(_mockUser as User?);
    }
    return _auth!.authStateChanges();
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    if (_isMockMode) {
      // Mock successful sign in
      await Future.delayed(const Duration(milliseconds: 500));
      return Future.value(MockUserCredential(
        user: _mockUser
      ) as UserCredential); // Mock credential
    }
    try {
      return await _auth!.signInWithEmailAndPassword(
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
      return Future.value(MockUserCredential(
        user: _mockUser
      ) as UserCredential); // Mock credential
    }
    try {
      // Create user authentication
      final userCredential = await _auth!.createUserWithEmailAndPassword(
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
    await _firestore!.collection('users').doc(userId).set({
      'username': username,
      'email': email,
      'bio': 'Terminal user',
      'terminalColor': 'green',
      'terminalTheme': 'dark',
      'terminalFontSize': 14.0,
      'terminalSound': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    if (_isMockMode) {
      // Mock sign out
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }
    await _auth!.signOut();
  }

  // Get user profile data
  Future<UserModel?> getUserProfile(String userId) async {
    if (_isMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockUserProfile;
    }
    
    try {
      final doc = await _firestore?.collection('users').doc(userId).get();
      if (doc != null && doc.exists) {
        return UserModel.fromJson(doc.data()!, userId);
      } else {
        // If user profile doesn't exist yet, create a new one
        final newUser = UserModel(
          id: userId,
          username: _auth?.currentUser?.displayName ?? 'user',
          email: _auth?.currentUser?.email ?? '',
          bio: 'Terminal user',
          terminalColor: 'green',
          terminalTheme: 'dark',
          terminalFontSize: 14.0,
          terminalSound: true,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
        await _firestore?.collection('users').doc(userId).set(newUser.toJson());
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
      await _firestore?.collection('users').doc(userId).update({
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
    if (_isMockMode) {
      return _mockUserProfile?.username == username;
    }
    
    try {
      final querySnapshot = await _firestore?.collection('users')
          .where('username', isEqualTo: username)
          .get();
      return querySnapshot != null && querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }
  
  // Get all users
  Future<QuerySnapshot?> getAllUsers() async {
    if (_isMockMode) {
      return null; // Mock implementation doesn't support this
    }
    return await _firestore?.collection('users').get();
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
