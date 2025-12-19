// lib/screens/group_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// আপনার ফাইল কাঠামো অনুযায়ী ইমপোর্ট
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/group_avatar.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.chatId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  // এটি MessageInput উইজেটের মাধ্যমে হ্যান্ডেল করা হবে,
  // তাই এখানে শুধু UI লজিক থাকবে।

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text(
              'Group Chat',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Expanded অংশটি এখন মেসেজ স্ট্রিম এবং মেসেজ বাবল রেন্ডার করবে
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Start the group conversation!'));
                }

                final loadedMessages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: loadedMessages.length,
                  itemBuilder: (context, index) {
                    final message = loadedMessages[index];
                    final messageData = message.data() as Map<String, dynamic>;

                    final currentSenderId = messageData['senderId'];
                    final currentMessageText = messageData['text'] ?? '';
                    final isMe = currentSenderId == _currentUserUid;
                    final senderName = messageData['senderName'] as String?;
                    final timestamp = messageData['timestamp'] as Timestamp;

                    // --- Time Display Logic (message_bubble.dart থেকে কপি করা) ---
                    bool shouldShowTime = false;
                    final nextIndex = index + 1;

                    if (index == 0) {
                      shouldShowTime = true;
                    } else if (nextIndex < loadedMessages.length) {
                      final nextMessageSenderId = loadedMessages[nextIndex].get('senderId');
                      if (nextMessageSenderId != currentSenderId) {
                        shouldShowTime = true;
                      } else {
                        shouldShowTime = false;
                      }
                    } else if (nextIndex == loadedMessages.length) {
                      shouldShowTime = true;
                    }
                    // ---------------------------

                    // ✅ MessageBubbleContent ব্যবহার করা হচ্ছে
                    // Note: আমরা _MessageBubbleContent উইজেটটিকে এখানে কপি করিনি।
                    // পরিবর্তে, আমরা ধরে নিচ্ছি আপনার MessageBubble উইজেটটি এখন
                    // অন্যান্য প্যারামিটার ছাড়া (শুধু chatId দিয়ে) মেসেজ লিস্ট দেখায়।
                    // যদি না দেখায়, তবে আপনাকে এটি ঠিক করতে হবে।

                    // ❌ যেহেতু আপনার lib/widgets/message_bubble.dart এ সমস্ত লজিক আছে,
                    // তাই 1-to-1 চ্যাটের মতোই শুধু chatId দিয়ে MessageBubble কল করা উচিত নয়।
                    // আপনাকে মেসেজ স্ট্রিম এখানে হ্যান্ডেল করতে হবে এবং মেসেজ বাবল উইজেট ব্যবহার করতে হবে।

                    // যেহেতু আপনি মেসেজ স্ট্রিম এখানে হ্যান্ডেল করছেন,
                    // তাই আপনি আপনার মূল 'lib/widgets/message_bubble.dart'
                    // ফাইলের 'MessageBubble' ক্লাসের পরিবর্তে,
                    // তার ভিতরের '_MessageBubbleContent' লজিকটি ব্যবহার করতে পারেন।

                    // --- Message Content Rendering (using _MessageBubbleContent logic from message_bubble.dart) ---
                    // এটি গ্রুপ চ্যাটের জন্য নতুন লজিক প্রয়োগ করবে

                    final messageTime = timestamp.toDate();
                    final timeString = TimeOfDay.fromDateTime(messageTime).format(context);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 2),
                              child: Text(
                                senderName ?? 'User',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          // এখানে আপনার কাস্টম বাবল রেন্ডারিং লজিক বা
                          // _MessageBubbleContent উইজেটটি ব্যবহার করুন।
                          // আপাতত ধরে নিচ্ছি আপনি আপনার মেসেজ বাবল উইজেটকে এইভাবে ব্যবহার করতে চান:
                          _GroupMessageBubbleContent(
                            key: ValueKey(message.id),
                            message: currentMessageText,
                            isMe: isMe,
                            timestamp: timestamp,
                            shouldShowTime: shouldShowTime,
                            senderName: senderName,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ✅ MessageInput ব্যবহার করা হলো (isGroupChat=true)
          MessageInput(
            chatId: widget.chatId,
            isGroupChat: true, // গ্রুপ চ্যাটের জন্য ফ্ল্যাগ
          ),
        ],
      ),
    );
  }
}

// যেহেতু আপনার _MessageBubbleContent ক্লাসে senderName নেই, তাই আমরা গ্রুপ চ্যাটের জন্য
// একটি সহজ উইজেট তৈরি করছি যা নাম দেখাবে।
class _GroupMessageBubbleContent extends StatelessWidget {
  const _GroupMessageBubbleContent({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.shouldShowTime,
    required this.senderName,
  });

  final String message;
  final bool isMe;
  final Timestamp timestamp;
  final bool shouldShowTime;
  final String? senderName;

  @override
  Widget build(BuildContext context) {
    // Determine Bubble colors based on isMe and theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;

    final bubbleColor = isMe
        ? primaryColor
        : (isDarkMode ? Theme.of(context).colorScheme.surface : Colors.grey.shade300);
    final textColor = isMe
        ? Colors.white
        : (isDarkMode ? Colors.white : Colors.black);

    final messageTime = timestamp.toDate();
    final timeString = TimeOfDay.fromDateTime(messageTime).format(context);

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) const SizedBox(width: 8),

            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : (shouldShowTime ? const Radius.circular(12) : const Radius.circular(4)),
                  bottomRight: isMe ? (shouldShowTime ? const Radius.circular(12) : const Radius.circular(4)) : const Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                ),
              ),
            ),

            if (isMe) const SizedBox(width: 8),
          ],
        ),

        if (shouldShowTime)
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 16,
              right: isMe ? 16 : 0,
              bottom: 12,
              top: 4,
            ),
            child: Text(
              timeString,
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }
}