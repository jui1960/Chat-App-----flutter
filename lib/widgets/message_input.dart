// lib/widgets/message_input.dart (FINAL CODE FOR 1-to-1 & GROUP CHAT)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageInput extends StatelessWidget {
  final String chatId;
  // ✅ গ্রুপ চ্যাট ফ্ল্যাগ যোগ করা হলো
  final bool isGroupChat;

  const MessageInput({
    super.key,
    required this.chatId,
    this.isGroupChat = false, // ডিফল্ট 1-to-1 চ্যাট
  });

  // existing function: chatId থেকে peerId বের করা (user1_user2 ফরম্যাট ধরে)
  String _getPeerId(String currentUserId, String fullChatId) {
    final ids = fullChatId.split('_');
    return ids.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  // New function to handle sending message logic (Unified for 1-to-1 and Group)
  void _sendMessage(BuildContext context, TextEditingController controller) async {
    final messageText = controller.text.trim();
    if (messageText.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final currentUserId = user.uid;
    String? peerId;

    // 1. peerId লজিক (শুধুমাত্র 1-to-1 চ্যাটের জন্য)
    if (!isGroupChat) {
      peerId = _getPeerId(currentUserId, chatId);
      if (peerId!.isEmpty) {
        debugPrint('Error: Could not determine peer ID from chatId: $chatId');
        return;
      }
    }

    final data = {
      'text': messageText,
      'timestamp': Timestamp.now(),
      'senderId': currentUserId,
      // গ্রুপ চ্যাটের জন্য senderName আবশ্যক
      'senderName': user.displayName ?? 'Anonymous',
    };

    try {
      final firestore = FirebaseFirestore.instance;
      final chatRef = firestore.collection('chats').doc(chatId);

      // 2. Save the message to Firestore
      await chatRef
          .collection('messages')
          .add(data);

      // 3. মেইন চ্যাট ডক তৈরি/আপডেট করা হলো
      final updateData = {
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.now(),
        'isGroup': isGroupChat, // ফ্ল্যাগ সেট করা হলো
      };

      // শুধুমাত্র 1-to-1 চ্যাটের জন্য members অ্যারে আপডেট করা
      if (!isGroupChat && peerId != null) {
        updateData['members'] = [currentUserId, peerId];
      }

      await chatRef.set(updateData, SetOptions(merge: true));

      // 4. Clear the input field
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