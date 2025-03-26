import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'widgets/terminal_typing.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize audio service for sound effects
  final audioService = AudioService();
  
  runApp(DemoTerminalApp(audioService: audioService));
}

class DemoTerminalApp extends StatelessWidget {
  final AudioService audioService;
  
  const DemoTerminalApp({super.key, required this.audioService});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BD Terminal Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          background: Colors.black,
          onBackground: Colors.greenAccent,
          primary: Colors.green,
        ),
        fontFamily: 'Courier',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          background: Colors.black,
          onBackground: Colors.greenAccent,
          primary: Colors.green,
        ),
        fontFamily: 'Courier',
      ),
      themeMode: ThemeMode.dark,
      home: DemoTerminalScreen(audioService: audioService),
    );
  }
}

class DemoTerminalScreen extends StatefulWidget {
  final AudioService audioService;
  
  const DemoTerminalScreen({super.key, required this.audioService});
  
  @override
  State<DemoTerminalScreen> createState() => _DemoTerminalScreenState();
}

class _DemoTerminalScreenState extends State<DemoTerminalScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _messages = [];
  String _currentTheme = 'dark';
  double _fontSize = 14.0;
  bool _soundEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _addSystemMessage("Welcome to BD Terminal Demo");
    _addSystemMessage("Terminal v2.0 with enhanced features:");
    _addSystemMessage("1. Typing animations");
    _addSystemMessage("2. Sound effects");
    _addSystemMessage("3. Theme customization");
    _addSystemMessage("4. Offline message storage");
    _addSystemMessage("");
    _addSystemMessage("Try these commands:");
    _addSystemMessage("/help - Show available commands");
    _addSystemMessage("/theme [dark|light|matrix] - Change theme");
    _addSystemMessage("/sound [on|off] - Toggle sound effects");
    _addSystemMessage("/fontsize [size] - Change font size");
    _addSystemMessage("/calc [expression] - Simple calculator");
  }
  
  void _addSystemMessage(String content) {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'system',
        'content': content,
        'timestamp': DateTime.now(),
      });
    });
  }
  
  void _addUserMessage(String content) {
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'user',
        'content': content,
        'timestamp': DateTime.now(),
      });
    });
    
    _handleCommand(content);
  }
  
  void _handleCommand(String input) {
    // Play key sound
    if (_soundEnabled) {
      widget.audioService.playKeySound();
    }
    
    if (input.startsWith('/')) {
      final parts = input.split(' ');
      final command = parts[0].toLowerCase();
      
      switch (command) {
        case '/help':
          _addSystemMessage("Available commands:");
          _addSystemMessage("/help - Show this help message");
          _addSystemMessage("/theme [dark|light|matrix] - Change theme");
          _addSystemMessage("/sound [on|off] - Toggle sound effects");
          _addSystemMessage("/fontsize [size] - Change font size");
          _addSystemMessage("/calc [expression] - Simple calculator");
          _addSystemMessage("/clear - Clear terminal");
          break;
          
        case '/theme':
          if (parts.length > 1) {
            final theme = parts[1].toLowerCase();
            setState(() {
              _currentTheme = theme;
            });
            _addSystemMessage("Theme changed to $theme");
          } else {
            _addSystemMessage("Current theme: $_currentTheme");
            _addSystemMessage("Usage: /theme [dark|light|matrix]");
          }
          break;
          
        case '/sound':
          if (parts.length > 1) {
            final sound = parts[1].toLowerCase();
            setState(() {
              _soundEnabled = sound == 'on';
            });
            _addSystemMessage("Sound effects ${_soundEnabled ? 'enabled' : 'disabled'}");
          } else {
            _addSystemMessage("Sound effects: ${_soundEnabled ? 'on' : 'off'}");
            _addSystemMessage("Usage: /sound [on|off]");
          }
          break;
          
        case '/fontsize':
          if (parts.length > 1) {
            try {
              final size = double.parse(parts[1]);
              setState(() {
                _fontSize = size;
              });
              _addSystemMessage("Font size changed to $size");
            } catch (e) {
              _addSystemMessage("Invalid font size. Usage: /fontsize [number]");
            }
          } else {
            _addSystemMessage("Current font size: $_fontSize");
            _addSystemMessage("Usage: /fontsize [number]");
          }
          break;
          
        case '/calc':
          if (parts.length > 1) {
            final expression = input.substring(6);
            try {
              // Simple calculator for demo
              final result = _evaluateExpression(expression);
              _addSystemMessage("Result: $result");
            } catch (e) {
              _addSystemMessage("Invalid expression: $expression");
            }
          } else {
            _addSystemMessage("Usage: /calc [expression]");
          }
          break;
          
        case '/clear':
          setState(() {
            _messages.clear();
          });
          _addSystemMessage("Terminal cleared");
          break;
          
        default:
          _addSystemMessage("Command not found: $command");
          _addSystemMessage("Type /help for available commands");
      }
    } else {
      // Echo back the message for the demo
      Future.delayed(const Duration(milliseconds: 500), () {
        _addSystemMessage("Echo: $input");
      });
    }
  }
  
  // Simple expression evaluator for demo
  double _evaluateExpression(String expression) {
    expression = expression.replaceAll(' ', '');
    
    // Handle addition and subtraction
    List<String> addParts = expression.split('+');
    if (addParts.length > 1) {
      return addParts.map((p) => _evaluateExpression(p)).reduce((a, b) => a + b);
    }
    
    List<String> subParts = expression.split('-');
    if (subParts.length > 1) {
      return subParts.first.isEmpty 
          ? -_evaluateExpression(subParts[1])
          : _evaluateExpression(subParts.first) - 
            subParts.skip(1).map((p) => _evaluateExpression(p)).reduce((a, b) => a + b);
    }
    
    // Handle multiplication and division
    List<String> mulParts = expression.split('*');
    if (mulParts.length > 1) {
      return mulParts.map((p) => _evaluateExpression(p)).reduce((a, b) => a * b);
    }
    
    List<String> divParts = expression.split('/');
    if (divParts.length > 1) {
      return divParts.map((p) => _evaluateExpression(p)).reduce((a, b) => a / b);
    }
    
    // Base case: just a number
    return double.parse(expression);
  }
  
  @override
  Widget build(BuildContext context) {
    Color getThemeColor() {
      switch (_currentTheme) {
        case 'light':
          return Colors.white;
        case 'matrix':
          return Colors.green;
        case 'dark':
        default:
          return Colors.black;
      }
    }
    
    Color getTextColor() {
      switch (_currentTheme) {
        case 'light':
          return Colors.black;
        case 'matrix':
        case 'dark':
        default:
          return Colors.greenAccent;
      }
    }
    
    return Scaffold(
      backgroundColor: getThemeColor(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index];
                  final isSystem = message['sender'] == 'system';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSystem ? 'system>' : 'user>',
                          style: TextStyle(
                            color: isSystem ? Colors.green : Colors.blue,
                            fontFamily: 'Courier',
                            fontSize: _fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isSystem 
                            ? TerminalTypingText(
                                text: message['content'],
                                typingSpeed: const Duration(milliseconds: 30),
                                style: TextStyle(
                                  color: getTextColor(),
                                  fontFamily: 'Courier',
                                  fontSize: _fontSize,
                                ),
                              )
                            : Text(
                                message['content'],
                                style: TextStyle(
                                  color: getTextColor(),
                                  fontFamily: 'Courier',
                                  fontSize: _fontSize,
                                ),
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'user>',
                    style: TextStyle(
                      color: Colors.blue,
                      fontFamily: 'Courier',
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontSize: _fontSize,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      cursorColor: Colors.white,
                      cursorWidth: 10,
                      cursorHeight: 18,
                      cursorRadius: const Radius.circular(0),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _addUserMessage(value);
                          _controller.clear();
                          _focusNode.requestFocus();
                        }
                      },
                      onTap: () {
                        if (_soundEnabled) {
                          widget.audioService.playKeySound();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
