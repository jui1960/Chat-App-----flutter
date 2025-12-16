// lib/widget/message_bubble.dart
import 'package:flutter/material.dart';

// --- Data Models ---
enum MessageType { sent, received }

class Message {
  final String text;
  final String time;
  final MessageType type;

  const Message({required this.text, required this.time, required this.type});
}
// --------------------

class MessageBubble extends StatelessWidget {
  final String chatId;

  const MessageBubble({super.key, required this.chatId});

  // Sample Chat Data (Replace with real data later)
  final List<Message> messages = const [
    Message(text: "Hello", time: "10:00 AM", type: MessageType.received),
    Message(text: "How your life is going?", time: "10:01 AM", type: MessageType.received),
    Message(text: "Not bad at all. I'd be sending it in 5 minutes.", time: "10:03 AM", type: MessageType.sent),
    Message(text: "Alright b. I'd be expecting it. Well-done.", time: "10:04 AM", type: MessageType.received),
    Message(text: "Thank you. Check your mail, I just sent it. See you at the office.", time: "10:07 AM", type: MessageType.sent),
    Message(text: "I'm onw to the meeting. See you there!", time: "10:09 AM", type: MessageType.received),
    Message(text: "When about you?", time: "10:10 AM", type: MessageType.sent),
    Message(text: "Not so good.", time: "10:11 AM", type: MessageType.sent),
  ];


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;

    return ListView.builder(
      reverse: true, // Show latest message at the bottom
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _buildSingleMessage(context, message, primaryColor, isDarkMode);
      },
    );
  }

  Widget _buildSingleMessage(BuildContext context, Message message, Color primaryColor, bool isDarkMode) {
    final isSent = message.type == MessageType.sent;
    final bubbleColor = isSent
        ? primaryColor.withOpacity(0.8)
        : isDarkMode ? const Color(0xFF283543) : const Color(0xFFF1F1F1);
    final textColor = isSent ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color;
    final timeColor = isSent ? Colors.white70 : Colors.grey;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: Radius.circular(isSent ? 15 : 5),
                  bottomRight: Radius.circular(isSent ? 5 : 15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
              child: Text(
                message.time,
                style: TextStyle(color: timeColor, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}