// lib/services/chat_service.dart (UPDATED)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ব্লক স্ট্যাটাস চেক করার জন্য একটি স্ট্রিমেবল ফাংশন
  Stream<DocumentSnapshot> getBlockStatus(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  // ✅ নতুন ফাংশন: ইউজারকে ব্লক বা আনব্লক করা
  Future<void> updateBlockStatus(String chatId, String peerId, bool shouldBlock) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final chatRef = _db.collection('chats').doc(chatId);

    // ব্লকিং স্ট্যাটাস সেভ করার জন্য দুটি ফিল্ড:
    // blockedBy_YOURID এবং blockedBy_PEERID
    final blockedByKey = 'blockedBy_$currentUserId';

    await chatRef.set(
      {
        blockedByKey: shouldBlock,
        // আমরা peerId কে ব্লক করলে, peerBlockedByCurrentUser সেট করব।
      },
      SetOptions(merge: true),
    );
  }

  // ... (getChats, getMessages, sendMessage লজিক একই থাকবে)

  Stream<QuerySnapshot> getChats(String userId) {
    return _db.collection('chats')
        .where('members', arrayContains: userId) // members ব্যবহার করা হয়েছে
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }


  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db.collection('chats').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true) // 'time' এর পরিবর্তে 'timestamp' ব্যবহার করা হলো
        .snapshots();
  }


  Future<void> sendMessage(String chatId, Map<String, dynamic> msg) async {
    // এই ফাংশনটি MessageInput এ ব্যবহৃত হয় না, এটি রেফারেন্স হিসেবে আছে।
    // MessageInput এর লজিক অনেক বিস্তারিত, তাই এটি অপরিবর্তিত রাখা হলো।
    final ref = _db.collection('chats').doc(chatId).collection('messages').doc();
    await ref.set(msg);
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': msg['text'],
      'lastMessageTime': msg['timestamp'], // 'time' এর পরিবর্তে 'timestamp' ব্যবহার করা হলো
    });
  }
}