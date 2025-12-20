import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageInput extends StatelessWidget {
  final String chatId;
  final bool isGroupChat;

  const MessageInput({
    super.key,
    required this.chatId,
    this.isGroupChat = false,
  });

  String _getPeerId(String currentUserId, String fullChatId) {
    final ids = fullChatId.split('_');
    return ids.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

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
      'senderName': user.displayName ?? 'Anonymous',
    };

    try {
      final firestore = FirebaseFirestore.instance;
      final chatRef = firestore.collection('chats').doc(chatId);

      await chatRef.collection('messages').add(data);

      final updateData = {
        'lastMessage': messageText,
        'lastMessageTime': Timestamp.now(),
        'isGroup': isGroupChat,
      };

      if (!isGroupChat && peerId != null) {
        updateData['members'] = [currentUserId, peerId];
      }

      await chatRef.set(updateData, SetOptions(merge: true));

      controller.clear();

    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message.')),
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
          // 1. Camera Icon
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: primaryColor),
            padding: const EdgeInsets.only(left: 5, right: 0),
            constraints: const BoxConstraints(minWidth: 30),
            onPressed: () {
              // TODO: Handle camera/photo picker
            },
          ),

          // 2. Voice Record Icon
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
              constraints: const BoxConstraints(minHeight: 45, maxHeight: 150),
              decoration: BoxDecoration(
                color: inputFillColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: controller,
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

                    },
                  ),
                ),
                minLines: 1,
                maxLines: 5,
                maxLength: 5000,
                buildCounter: (BuildContext context, {required int currentLength, required int? maxLength, required bool isFocused}) => null,
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
              onPressed: () => _sendMessage(context, controller),
            ),
          ),
        ],
      ),
    );
  }
}