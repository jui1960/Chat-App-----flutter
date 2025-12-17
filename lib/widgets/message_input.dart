// lib/widget/message_input.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW
import 'package:firebase_auth/firebase_auth.dart';     // NEW

class MessageInput extends StatelessWidget {
  final String chatId;

  const MessageInput({super.key, required this.chatId});

  // New function to handle sending message logic
  void _sendMessage(BuildContext context, TextEditingController controller) async {
    final messageText = controller.text.trim();
    if (messageText.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle not logged in case (should not happen if routing is correct)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final data = {
      'text': messageText,
      'timestamp': Timestamp.now(),
      'senderId': user.uid,
      'senderName': user.displayName ?? 'Anonymous',
    };

    try {
      // 1. Save the message to Firestore
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(data);

      // 2. Optional: Update the parent chat document with the last message info
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.now(),
        // Participants should also be saved here if the chat is new
      }, SetOptions(merge: true));

      // 3. Clear the input field
      controller.clear();

    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final inputFillColor = isDarkMode ? const Color(0xFF1E2733) : Colors.white;
    final controller = TextEditingController();
    final hintTextColor = isDarkMode ? Colors.white : Colors.black;


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      color: scaffoldColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Camera Icon (Leftmost)
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: primaryColor),
            padding: const EdgeInsets.only(left: 5, right: 0),
            constraints: const BoxConstraints(minWidth: 30),
            onPressed: () {
              // TODO: Handle camera/photo picker
            },
          ),

          // 2. Voice Record Icon (Next to Camera)
          IconButton(
            icon: Icon(Icons.mic_none, color: primaryColor),
            padding: const EdgeInsets.only(left: 0, right: 5),
            constraints: const BoxConstraints(minWidth: 30),
            onPressed: () { /* TODO: startVoiceRecording */ },
          ),

          // 3. Text Input Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 10),
              height: 45,
              decoration: BoxDecoration(
                color: inputFillColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: controller,
                // Use the new send message function
                onSubmitted: (_) => _sendMessage(context, controller),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                  hintStyle: TextStyle(color: hintTextColor.withOpacity(0.6)),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.attach_file, color: primaryColor, size: 20),
                    onPressed: () {
                      // TODO: Handle attachment/file picker
                    },
                  ),
                ),
                minLines: 1,
                maxLines: 5,
              ),
            ),
          ),

          // 4. Send Button
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              // Use the new send message function
              onPressed: () => _sendMessage(context, controller),
            ),
          ),
        ],
      ),
    );
  }
}