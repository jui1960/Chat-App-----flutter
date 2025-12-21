import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class MessageBubble extends StatelessWidget {
  final String chatId;

  const MessageBubble({
    super.key,
    required this.chatId,
  });

  // এই ফাংশনটি টাইমস্ট্যাম্পকে একটি উইজেট হিসেবে রেন্ডার করে
  Widget _buildTimeWidget(Timestamp timestamp, bool isMe, BuildContext context) {
    final timeString = DateFormat('h:mm a').format(timestamp.toDate());
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 16,
        right: isMe ? 16 : 0,
        bottom: 8,
        top: 2,
      ),
      child: Text(
        timeString,
        style: TextStyle(
          fontSize: 10,
          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Say Hi to start the conversation!'));
        }

        final loadedMessages = chatSnapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.only(bottom: 10, top: 10),
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final message = loadedMessages[index];
            final messageData = message.data() as Map<String, dynamic>;

            final currentSenderId = messageData['senderId'];
            final isMe = currentSenderId == currentUserId;
            final messageText = messageData['text'] ?? '';
            final timestamp = messageData['timestamp'] as Timestamp;

            // টাইমস্ট্যাম্প দেখানোর লজিক
            bool shouldShowTime = false;
            final nextIndex = index + 1;

            if (index == 0) {
              // প্রথম মেসেজ সবসময় টাইম দেখাবে
              shouldShowTime = true;
            } else if (nextIndex < loadedMessages.length) {
              final nextMessageSenderId = loadedMessages[nextIndex].get('senderId');
              final nextMessageTime = loadedMessages[nextIndex].get('timestamp') as Timestamp;

              // যদি পরবর্তী মেসেজ অন্য সেন্ডারের হয়
              if (nextMessageSenderId != currentSenderId) {
                shouldShowTime = true;
              } else {
                // একই সেন্ডার হলেও, যদি দুটি মেসেজের মধ্যে সময়ের ব্যবধান বেশি হয় (যেমন ৫ মিনিট), তবে টাইম দেখাবে
                final difference = timestamp.toDate().difference(nextMessageTime.toDate()).inMinutes;
                if (difference > 5) {
                  shouldShowTime = true;
                }
              }
            } else if (nextIndex == loadedMessages.length) {
              // যদি শেষ মেসেজ হয়
              shouldShowTime = true;
            }


            return Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: _MessageBubbleContent(
                    key: ValueKey(message.id),
                    message: messageText,
                    isMe: isMe,
                  ),
                ),
                // মেসেজ বাবলের নিচে টাইমস্ট্যাম্প দেখানো
                if (shouldShowTime) _buildTimeWidget(timestamp, isMe, context),
              ],
            );
          },
        );
      },
    );
  }
}


class _MessageBubbleContent extends StatelessWidget {
  const _MessageBubbleContent({
    super.key,
    required this.message,
    required this.isMe,
  });

  final String message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;

    final bubbleColor = isMe
        ? primaryColor
        : (isDarkMode ? Theme.of(context).colorScheme.surface : Colors.grey.shade200);
    final textColor = isMe
        ? Colors.white
        : (isDarkMode ? Colors.white : Colors.black);


    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}