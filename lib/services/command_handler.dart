import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'chat_service.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class CommandHandler {
  final ChatService _chatService;
  final AuthService _authService;

  CommandHandler(this._chatService, this._authService);

  static const Map<String, String> helpText = {
    '/help': 'Show available commands',
    '/clear': 'Clear chat history',
    '/time': 'Show current time',
    '/echo': 'Echo back the provided text',
    '/color': 'Change text color (e.g., /color red)',
    '/status': 'Show system status',
    '/profile': 'View your profile information',
    '/bio': 'Set your bio (e.g., /bio I love terminals!)',
    '/logout': 'Log out from your account',
    '/users': 'List active users',
  };

  Future<Message?> handleCommand(String command, String userId) async {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    switch (cmd) {
      case '/help':
        return _helpCommand(userId);
      case '/clear':
        return _clearCommand(userId);
      case '/time':
        return _timeCommand(userId);
      case '/echo':
        return _echoCommand(userId, args);
      case '/color':
        return _colorCommand(userId, args);
      case '/status':
        return _statusCommand(userId);
      case '/profile':
        return await _profileCommand(userId);
      case '/bio':
        return await _bioCommand(userId, args);
      case '/logout':
        return await _logoutCommand(userId);
      case '/users':
        return await _usersCommand(userId);
      default:
        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          content: 'Unknown command: $cmd. Type /help for available commands.',
          timestamp: DateTime.now(),
          isCommand: true,
        );
    }
  }

  Message _helpCommand(String userId) {
    final helpMessage = helpText.entries
        .map((e) => '${e.key} - ${e.value}')
        .join('\n');
    
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: 'Available commands:\n$helpMessage',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Future<Message> _clearCommand(String userId) async {
    await _chatService.clearChat();
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: 'Chat history cleared.',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Message _timeCommand(String userId) {
    final now = DateTime.now();
    return Message(
      id: now.millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: 'Current time: ${now.toLocal()}',
      timestamp: now,
      isCommand: true,
    );
  }

  Message _echoCommand(String userId, String args) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: args.isEmpty ? 'Echo: [no message provided]' : 'Echo: $args',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Message _colorCommand(String userId, String color) {
    final validColors = {
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'yellow': Colors.yellow,
      'white': Colors.white,
      'cyan': Colors.cyan,
      'magenta': Colors.purple,
    };

    if (color.isEmpty) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Available colors: ${validColors.keys.join(", ")}',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    if (!validColors.containsKey(color.toLowerCase())) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Invalid color. Available colors: ${validColors.keys.join(", ")}',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    // Update user's preferred color in profile
    if (_authService.currentUser != null) {
      _authService.updateUserProfile(
        _authService.currentUser!.uid,
        {'terminalColor': color.toLowerCase()},
      );
    }

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: 'Text color changed to $color',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Message _statusCommand(String userId) {
    final isLoggedIn = _authService.currentUser != null;
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: '''System Status:
- Terminal: Active
- Connection: Online
- Auth Status: ${isLoggedIn ? 'Logged In' : 'Not Logged In'}
- User ID: ${isLoggedIn ? _authService.currentUser!.uid.substring(0, 6) + '...' : 'N/A'}
- Memory Usage: Nominal
- System Time: ${DateTime.now().toLocal()}''',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Future<Message> _profileCommand(String userId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'You are not logged in. Please log in to view your profile.',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    final profileData = await _authService.getUserProfile(currentUser.uid);
    if (profileData == null) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Profile data not found.',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    final user = UserModel.fromJson(profileData, currentUser.uid);
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: '''User Profile:
- Username: ${user.username}
- Email: ${user.email}
- Bio: ${user.bio}
- Terminal Color: ${user.terminalColor}
- Account Created: ${user.createdAt.toLocal().toString().split('.')[0]}
- Last Active: ${user.lastActive.toLocal().toString().split('.')[0]}
''',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Future<Message> _bioCommand(String userId, String bio) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'You are not logged in. Please log in to update your bio.',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    if (bio.isEmpty) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Usage: /bio Your new bio text',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    try {
      await _authService.updateUserProfile(
        currentUser.uid,
        {'bio': bio},
      );

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Bio updated successfully to: "$bio"',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    } catch (e) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Failed to update bio: $e',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }
  }

  Future<Message> _logoutCommand(String userId) async {
    try {
      await _authService.signOut();
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Logged out successfully. Please log in again.',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    } catch (e) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Failed to log out: $e',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }
  }

  Future<Message> _usersCommand(String userId) async {
    try {
      final usersSnapshot = await _authService.getAllUsers();
      
      if (usersSnapshot.docs.isEmpty) {
        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          content: 'No users found.',
          timestamp: DateTime.now(),
          isCommand: true,
        );
      }

      final users = usersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final username = data['username'] ?? 'Unknown';
        final lastActive = data['lastActive'] != null 
            ? (data['lastActive'] as Timestamp).toDate().toString().split('.')[0] 
            : 'Unknown';
        return '- $username (Last active: $lastActive)';
      }).join('\n');

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Users:\n$users',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    } catch (e) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Failed to fetch users: $e',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }
  }
}
