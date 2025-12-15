import 'package:cloud_firestore/cloud_firestore.dart';


class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Stream<QuerySnapshot> getChats(String userId) {
    return _db.collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }


  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
        .orderBy('time', descending: true)
        .snapshots();
  }


  Future<void> sendMessage(String chatId, Map<String, dynamic> msg) async {
    final ref = _db.collection('chats').doc(chatId).collection('messages').doc();
    await ref.set(msg);
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': msg['text'],
      'lastMessageTime': msg['time'],
    });
  }
}