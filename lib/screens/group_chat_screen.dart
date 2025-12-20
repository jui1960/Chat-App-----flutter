import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Alias ব্যবহার করা হলো
import '../widgets/message_input.dart' as InputWidget;
// MessageBubble-এর জন্য কোন Alias প্রয়োজন নেই কারণ আমরা _GroupMessageBubbleContent ব্যবহার করছি
// কিন্তু যদি মূল MessageBubble-ও ব্যবহার করা হয়, তবে Alias দরকার হবে।
// যেহেতু মেসেজ স্ট্রিম এখানে হ্যান্ডেল হচ্ছে, তাই শুধু InputWidget-এর Alias যথেষ্ট।
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

                    // Time Display Logic
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

          // Alias ব্যবহার করে MessageInput কল করা হলো
          InputWidget.MessageInput(
            chatId: widget.chatId,
            isGroupChat: true,
          ),
        ],
      ),
    );
  }
}

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