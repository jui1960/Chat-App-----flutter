
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  Stream<DocumentSnapshot> getBlockStatus(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }


  Future<void> updateBlockStatus(String chatId, String peerId, bool shouldBlock) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatRef = _db.collection('chats').doc(chatId);


    final blockedByKey = 'blockedBy_$currentUserId';

    await chatRef.set(
      {
        blockedByKey: shouldBlock,

      },
      SetOptions(merge: true),
    );
  }



  Stream<QuerySnapshot> getChats(String userId) {
    return _db.collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }


  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }


  Future<void> sendMessage(String chatId, Map<String, dynamic> msg) async {

    final ref = _db.collection('chats').doc(chatId).collection('messages').doc();
    await ref.set(msg);
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': msg['text'],
      'lastMessageTime': msg['timestamp'],
    });
  }
}