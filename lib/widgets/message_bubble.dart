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


            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: _MessageBubbleContent(
                key: ValueKey(message.id),
                message: messageText,
                isMe: isMe,
                timestamp: timestamp,
              ),
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
    required this.timestamp,
  });

  final String message;
  final bool isMe;
  final Timestamp timestamp;

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

    final timeString = DateFormat('jm').format(timestamp.toDate());

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}