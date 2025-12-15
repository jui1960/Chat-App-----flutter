import 'package:flutter/material.dart';


class MessageInput extends StatelessWidget {
  final String chatId;
  const MessageInput({super.key, required this.chatId});


  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Type a message'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
// Firestore send message logic here
            controller.clear();
          },
        ),
      ],
    );
  }
}