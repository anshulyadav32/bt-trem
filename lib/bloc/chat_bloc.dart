import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/command_handler.dart';
import '../services/auth_service.dart';

// Events
abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String content;
  final String senderId;
  SendMessageEvent(this.content, this.senderId);
}

class LoadMessagesEvent extends ChatEvent {}

class ClearChatEvent extends ChatEvent {}

// States
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final String currentColor;
  ChatLoaded(this.messages, {this.currentColor = 'green'});
}

class ChatError extends ChatState {
  final String error;
  ChatError(this.error);
}

// Bloc
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;
  final AuthService _authService;
  final CommandHandler _commandHandler;
  String _currentColor = 'green';

  ChatBloc(this._chatService, this._authService)
      : _commandHandler = CommandHandler(_chatService, _authService),
        super(ChatInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ClearChatEvent>(_onClearChat);
  }

  void _onLoadMessages(LoadMessagesEvent event, Emitter<ChatState> emit) {
    try {
      emit(ChatLoading());
      _chatService.getMessages().listen(
        (messages) {
          emit(ChatLoaded(messages, currentColor: _currentColor));
        },
        onError: (error) {
          emit(ChatError('Failed to load messages: $error'));
        },
      );
    } catch (e) {
      emit(ChatError('Failed to load messages: $e'));
    }
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatState> emit) async {
    try {
      if (event.content.startsWith('/')) {
        final response = await _commandHandler.handleCommand(
          event.content,
          event.senderId,
        );
        
        if (response != null) {
          await _chatService.sendMessage(response);
          
          // Handle color command specifically
          if (event.content.startsWith('/color ')) {
            final parts = event.content.split(' ');
            if (parts.length > 1) {
              final color = parts[1].toLowerCase();
              if (['red', 'green', 'blue', 'yellow', 'white', 'cyan', 'magenta']
                  .contains(color)) {
                _currentColor = color;
                
                // Update user's preferred color in profile if logged in
                if (_authService.currentUser != null) {
                  await _authService.updateUserProfile(
                    _authService.currentUser!.uid,
                    {'terminalColor': color},
                  );
                }
                
                if (state is ChatLoaded) {
                  emit(ChatLoaded((state as ChatLoaded).messages,
                      currentColor: _currentColor));
                }
              }
            }
          }
        }
      }

      final userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: event.senderId,
        content: event.content,
        timestamp: DateTime.now(),
        isCommand: event.content.startsWith('/'),
      );
      await _chatService.sendMessage(userMessage);
    } catch (e) {
      emit(ChatError('Failed to send message: $e'));
    }
  }

  Future<void> _onClearChat(ClearChatEvent event, Emitter<ChatState> emit) async {
    try {
      await _chatService.clearChat();
    } catch (e) {
      emit(ChatError('Failed to clear chat: $e'));
    }
  }
}
