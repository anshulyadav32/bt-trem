import 'package:cloud_firestore/cloud_firestore.dart';

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
      username: json['username'] ?? 'user',
      email: json['email'] ?? '',
      bio: json['bio'] ?? 'Terminal user',
      terminalColor: json['terminalColor'] ?? 'green',
      terminalTheme: json['terminalTheme'] ?? 'dark',
      terminalFontSize: (json['terminalFontSize'] as num?)?.toDouble() ?? 14.0,
      terminalSound: json['terminalSound'] == 'on' || json['terminalSound'] == true,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (json['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      'terminalSound': terminalSound ? 'on' : 'off',
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }
  
  UserModel copyWith({
    String? username,
    String? email,
    String? bio,
    String? terminalColor,
    String? terminalTheme,
    double? terminalFontSize,
    bool? terminalSound,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      terminalColor: terminalColor ?? this.terminalColor,
      terminalTheme: terminalTheme ?? this.terminalTheme,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      terminalSound: terminalSound ?? this.terminalSound,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
