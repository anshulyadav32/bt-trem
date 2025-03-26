import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'messages';

  Stream<List<Message>> getMessages() {
    return _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> sendMessage(Message message) async {
    try {
      await _firestore.collection(_collectionName).add(message.toJson());
    } catch (e) {
      print('Error sending message: $e');
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
    } catch (e) {
      print('Error clearing chat: $e');
      rethrow;
    }
  }
}
