import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import 'local_storage_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage;
  final String _collectionName = 'messages';
  
  ChatService({LocalStorageService? localStorage}) 
      : _localStorage = localStorage ?? LocalStorageService();
  
  Stream<List<Message>> getMessages() {
    return _firestore
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
      
      // Then send to Firestore
      await _firestore.collection(_collectionName).add(message.toJson());
    } catch (e) {
      print('Error sending message: $e');
      // Message is still saved locally and can be synced later
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_collectionName).doc(messageId).delete();
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  Future<void> clearChat() async {
    try {
      final messages = await _firestore.collection(_collectionName).get();
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
