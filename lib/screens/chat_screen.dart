import 'package:flutter/material.dart';
import '../widget/message_bubble.dart';
import '../widget/message_input.dart';


class ChatScreen extends StatelessWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(child: MessageBubble(chatId: chatId)),
          MessageInput(chatId: chatId),
        ],
      ),
    );
  }
}