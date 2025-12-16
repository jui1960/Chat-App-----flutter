// lib/widget/message_input.dart
import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final String chatId;

  const MessageInput({super.key, required this.chatId});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final inputFillColor = isDarkMode ? const Color(0xFF1E2733) : Colors.white;
    final controller = TextEditingController();

    void sendMessage() {
      if (controller.text.trim().isNotEmpty) {
        String message = controller.text;
        // TODO: Implement actual Firestore send logic
        debugPrint('Sending message to $chatId: $message');
        controller.clear();
      }
    }

    void startVoiceRecording() {
      // TODO: Implement voice recording logic
      debugPrint('Starting voice recording...');
    }

    return Container(
      // Padding reduced to 3 horizontally to give maximum space
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      color: scaffoldColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Camera Icon (Leftmost)
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: primaryColor),
            // Minimal padding
            padding: const EdgeInsets.only(left: 5, right: 0),
            constraints: const BoxConstraints(minWidth: 30),
            onPressed: () {
              // TODO: Handle camera/photo picker
            },
          ),

          // 2. Voice Record Icon (Next to Camera)
          IconButton(
            icon: Icon(Icons.mic_none, color: primaryColor),
            // Minimal padding
            padding: const EdgeInsets.only(left: 0, right: 5),
            constraints: const BoxConstraints(minWidth: 30),
            onPressed: startVoiceRecording,
          ),

          // *** REMOVED: Removed the SizedBox that was creating extra space ***

          // 3. Text Input Field (Now takes maximum available space up to the voice icon)
          Expanded(
            child: Container(
              // Reduced internal left padding of the text field
              padding: const EdgeInsets.only(left: 10),
              height: 45,
              decoration: BoxDecoration(
                color: inputFillColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: (_) => sendMessage(),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),

                  // Attachment Icon (Inside)
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

          // 4. Send Button (Outside the text field)
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}