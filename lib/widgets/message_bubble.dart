// lib/widget/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageBubble extends StatelessWidget {
  final String chatId;

  const MessageBubble({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("Please log in to see messages."));
    }

    return StreamBuilder<QuerySnapshot>(
      // Firestore query: Fetch messages, sorted by timestamp (descending order)
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Say hi!"));
        }

        final loadedMessages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true, // Display latest messages at the bottom
          padding: const EdgeInsets.all(8),
          itemCount: loadedMessages.length,
          itemBuilder: (context, index) {
            final message = loadedMessages[index];
            final messageData = message.data() as Map<String, dynamic>;

            final currentSenderId = messageData['senderId'];
            final currentMessageText = messageData['text'];
            final isMe = currentSenderId == currentUser.uid;

            // --- Time Display Logic ---
            bool shouldShowTime = false;
            final nextIndex = index + 1;


            if (index == 0) {
              shouldShowTime = true; // Always show time for the newest message
            } else if (nextIndex < loadedMessages.length) {
              final nextMessageSenderId = loadedMessages[nextIndex].get('senderId');

              // Show time if the next (older) message's sender ID is DIFFERENT from the current one.
              // This marks the end of a consecutive message block.
              if (nextMessageSenderId != currentSenderId) {
                shouldShowTime = true;
              } else {
                shouldShowTime = false;
              }
            } else if (nextIndex == loadedMessages.length) {
              // This means the current message is the oldest message,
              // it should show time if it's the start of a block (which it is, by default)
              shouldShowTime = true;
            }
            // ---------------------------

            // --- Message Content Rendering ---
            return _MessageBubbleContent(
              key: ValueKey(message.id),
              message: currentMessageText,
              isMe: isMe,
              timestamp: messageData['timestamp'] as Timestamp,
              shouldShowTime: shouldShowTime,
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
    required this.shouldShowTime,
  });

  final String message;
  final bool isMe;
  final Timestamp timestamp;
  final bool shouldShowTime;

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

    // Convert Firestore Timestamp to DateTime and format time
    final messageTime = timestamp.toDate();
    final timeString = TimeOfDay.fromDateTime(messageTime).format(context); // e.g., "1:02 PM"

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Horizontal spacing adjustment
            if (!isMe) const SizedBox(width: 8),

            // The actual message container
            Container(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  // Grouping visual changes:
                  // If time is not shown, slightly flatten the corner closest to the next bubble
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

        // Time Display Implementation
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