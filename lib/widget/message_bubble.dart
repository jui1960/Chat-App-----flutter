import 'package:flutter/material.dart';


class MessageBubble extends StatelessWidget {
  final String chatId;
  const MessageBubble({super.key, required this.chatId});


  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Messages for $chatId appear here'));
  }
}