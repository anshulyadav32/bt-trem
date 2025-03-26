import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bd_terminal/bloc/chat_bloc.dart';
import 'package:bd_terminal/bloc/auth_bloc.dart';
import 'package:bd_terminal/services/chat_service.dart';
import 'package:bd_terminal/services/auth_service.dart';
import 'package:bd_terminal/config/theme.dart';
import 'package:bd_terminal/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final chatService = ChatService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(chatService, authService),
        ),
      ],
      child: MaterialApp(
        title: 'BD Terminal',
        theme: AppTheme.darkTheme,
        home: AuthWrapper(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                // Add LoadMessagesEvent to ChatBloc when authenticated
                context.read<ChatBloc>().add(LoadMessagesEvent());
                
                return const ChatTerminal();
              } else {
                // This shouldn't be visible as AuthWrapper handles unauthenticated state
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class ChatTerminal extends StatefulWidget {
  const ChatTerminal({super.key});

  @override
  State<ChatTerminal> createState() => _ChatTerminalState();
}

class _ChatTerminalState extends State<ChatTerminal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Color _getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'white':
        return Colors.white;
      case 'cyan':
        return Colors.cyan;
      case 'magenta':
        return Colors.purple;
      case 'green':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is Authenticated) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  const Text('BD Terminal'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      authState.userProfile.username,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    context.read<ChatBloc>().add(
                          SendMessageEvent('/profile', authState.user.uid),
                        );
                  },
                  tooltip: 'View Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    context.read<ChatBloc>().add(ClearChatEvent());
                  },
                  tooltip: 'Clear Chat',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<AuthBloc>().add(SignOutEvent());
                  },
                  tooltip: 'Logout',
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: BlocBuilder<ChatBloc, ChatState>(
                    builder: (context, state) {
                      if (state is ChatLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state is ChatLoaded) {
                        // Get user's preferred color from profile
                        final preferredColor = authState.userProfile.terminalColor;
                        final effectiveColor = state.currentColor.isEmpty ? 
                            preferredColor : state.currentColor;
                        
                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  const Text('> ', style: TextStyle(color: Colors.green)),
                                  Expanded(
                                    child: Text(
                                      message.content,
                                      style: TextStyle(
                                        color: message.isCommand
                                            ? Colors.yellow
                                            : _getColor(effectiveColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else if (state is ChatError) {
                        return Center(child: Text(state.error));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('> ', style: TextStyle(color: Colors.green)),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(
                            color: _getColor(authState.userProfile.terminalColor),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: _getColor(authState.userProfile.terminalColor).withOpacity(0.5),
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              context.read<ChatBloc>().add(
                                    SendMessageEvent(value, authState.user.uid),
                                  );
                              _messageController.clear();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // This shouldn't be visible as AuthWrapper handles unauthenticated state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
