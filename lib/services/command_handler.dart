import 'package:flutter/material.dart';
import '../models/message.dart';
import 'chat_service.dart';
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class CommandHandler {
  final ChatService _chatService;
  final AuthService _authService;
  final bool _useFirebase;

  CommandHandler(this._chatService, this._authService, {bool useFirebase = false}) 
    : _useFirebase = useFirebase;

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
    '/theme': 'Change terminal theme (e.g., /theme dark)',
    '/sound': 'Toggle terminal sounds on/off',
    '/calc': 'Simple calculator (e.g., /calc 2+2)',
    '/fontsize': 'Change font size (e.g., /fontsize 14)',
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
      case '/theme':
        return _themeCommand(userId, args);
      case '/sound':
        return _soundCommand(userId, args);
      case '/calc':
        return _calcCommand(userId, args);
      case '/fontsize':
        return _fontSizeCommand(userId, args);
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
- User ID: ${isLoggedIn ? '${_authService.currentUser!.uid.substring(0, 6)}...' : 'N/A'}
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
        content: 'Error: Unable to retrieve user profile data.',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    final user = profileData;
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
      // If we're in mock mode, return placeholder message
      if (!_useFirebase) {
        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          content: 'Users feature is only available when connected to a database.',
          timestamp: DateTime.now(),
          isCommand: true,
        );
      }
      
      final usersSnapshot = await _authService.getAllUsers();
      
      if (usersSnapshot == null || usersSnapshot.docs.isEmpty) {
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

  Message _themeCommand(String userId, String theme) {
    final validThemes = {
      'dark': 'Dark theme',
      'light': 'Light theme',
    };

    if (theme.isEmpty) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Available themes: ${validThemes.keys.join(", ")}',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    if (!validThemes.containsKey(theme.toLowerCase())) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Invalid theme. Available themes: ${validThemes.keys.join(", ")}',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    // Update user's preferred theme in profile
    if (_authService.currentUser != null) {
      _authService.updateUserProfile(
        _authService.currentUser!.uid,
        {'terminalTheme': theme.toLowerCase()},
      );
    }

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: 'Theme changed to $theme',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Message _soundCommand(String userId, String sound) {
    final validSounds = {
      'on': 'Sounds on',
      'off': 'Sounds off',
    };

    if (sound.isEmpty) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Available sound options: ${validSounds.keys.join(", ")}',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    if (!validSounds.containsKey(sound.toLowerCase())) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Invalid sound option. Available sound options: ${validSounds.keys.join(", ")}',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }

    // Update user's preferred sound in profile
    if (_authService.currentUser != null) {
      _authService.updateUserProfile(
        _authService.currentUser!.uid,
        {'terminalSound': sound.toLowerCase()},
      );
    }

    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      content: 'Sound changed to $sound',
      timestamp: DateTime.now(),
      isCommand: true,
    );
  }

  Message _calcCommand(String userId, String calc) {
    try {
      final result = _evaluateExpression(calc);
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Calculation result: $result',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    } catch (e) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Invalid calculation: $e',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }
  }

  double _evaluateExpression(String expression) {
    expression = expression.replaceAll(' ', '');
    
    try {
      // Handle addition
      if (expression.contains('+')) {
        final parts = expression.split('+');
        return parts.map((p) => _evaluateExpression(p)).reduce((a, b) => a + b);
      }
      
      // Handle subtraction
      if (expression.contains('-')) {
        final parts = expression.split('-');
        return parts.first.isEmpty 
            ? -_evaluateExpression(parts.last) 
            : _evaluateExpression(parts.first) - parts.skip(1).map((p) => _evaluateExpression(p)).reduce((a, b) => a + b);
      }
      
      // Handle multiplication
      if (expression.contains('*')) {
        final parts = expression.split('*');
        return parts.map((p) => _evaluateExpression(p)).reduce((a, b) => a * b);
      }
      
      // Handle division
      if (expression.contains('/')) {
        final parts = expression.split('/');
        return parts.map((p) => _evaluateExpression(p)).reduce((a, b) {
          if (b == 0) throw Exception('Division by zero');
          return a / b;
        });
      }
      
      // Parse the number
      return double.parse(expression);
    } catch (e) {
      throw Exception('Invalid expression format');
    }
  }

  Message _fontSizeCommand(String userId, String fontSize) {
    try {
      final size = int.parse(fontSize);
      if (size < 10 || size > 24) {
        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: 'system',
          content: 'Invalid font size. Please choose a size between 10 and 24.',
          timestamp: DateTime.now(),
          isCommand: true,
        );
      }

      // Update user's preferred font size in profile
      if (_authService.currentUser != null) {
        _authService.updateUserProfile(
          _authService.currentUser!.uid,
          {'terminalFontSize': size},
        );
      }

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Font size changed to $size',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    } catch (e) {
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'system',
        content: 'Invalid font size: $e',
        timestamp: DateTime.now(),
        isCommand: true,
      );
    }
  }
}
