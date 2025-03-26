import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'local_storage_service.dart';
import 'dart:async';

class ChatService {
  final FirebaseFirestore? _firestore;
  final LocalStorageService _localStorage;
  final String _collectionName = 'messages';
  final bool _isMockMode;
  final StreamController<List<Message>> _mockMessagesController = StreamController<List<Message>>.broadcast();
  List<Message> _mockMessages = [];
  
  ChatService({LocalStorageService? localStorage, bool useFirebase = false}) 
      : _localStorage = localStorage ?? LocalStorageService(),
        _isMockMode = !useFirebase,
        _firestore = useFirebase ? FirebaseFirestore.instance : null {
    if (_isMockMode) {
      // Initialize with local messages in mock mode
      _mockMessages = _localStorage.getMessages();
      _mockMessagesController.add(_mockMessages);
    }
  }
  
  Stream<List<Message>> getMessages() {
    if (_isMockMode) {
      return _mockMessagesController.stream;
    }
    
    return _firestore!
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => Message.fromJson(doc.data()))
              .toList();
          
          // Cache messages locally if local storage is initialized
          for (var message in messages) {
            _localStorage.saveMessage(message);
          }
          
          return messages;
        });
  }
  
  // For offline mode, get messages from local storage
  List<Message> getLocalMessages() {
    return _localStorage.getMessages();
  }
  
  Future<void> sendMessage(Message message) async {
    try {
      // Save locally first for offline mode
      await _localStorage.saveMessage(message);
      
      if (_isMockMode) {
        // In mock mode, only save locally and update the stream
        _mockMessages.insert(0, message); // Add at the beginning for "newest first"
        _mockMessagesController.add(_mockMessages);
        return;
      }
      
      // Then send to Firestore
      await _firestore!.collection(_collectionName).add(message.toJson());
    } catch (e) {
      print('Error sending message: $e');
      // Message is still saved locally and can be synced later
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      if (_isMockMode) {
        // In mock mode, only delete locally
        _mockMessages.removeWhere((message) => message.id == messageId);
        _mockMessagesController.add(_mockMessages);
        await _localStorage.deleteMessage(messageId);
        return;
      }
      
      await _firestore!.collection(_collectionName).doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  Future<void> clearChat() async {
    try {
      if (_isMockMode) {
        // In mock mode, only clear locally
        _mockMessages.clear();
        _mockMessagesController.add(_mockMessages);
        await _localStorage.clearMessages();
        return;
      }
      
      final messages = await _firestore!.collection(_collectionName).get();
      for (var message in messages.docs) {
        await message.reference.delete();
      }
      
      // Clear local messages as well
      await _localStorage.clearMessages();
    } catch (e) {
      print('Error clearing chat: $e');
      rethrow;
    }
  }
}
