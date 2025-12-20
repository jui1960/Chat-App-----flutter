
import 'package:flutter/material.dart';

class GroupAvatar extends StatelessWidget {
  final List<String> initials;
  final double radius;
  final String? groupName;

  const GroupAvatar({
    super.key,
    required this.initials,
    this.radius = 28,
    this.groupName,
  });

  String _getDisplayInitials() {
    if (groupName != null && groupName!.isNotEmpty) {

      return groupName![0].toUpperCase();
    }

    return initials.take(3).join();
  }

  @override
  Widget build(BuildContext context) {
    final displayInitials = _getDisplayInitials();
    final backgroundColor = Theme.of(context).colorScheme.primary;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor.withOpacity(0.8),
      child: Text(
        displayInitials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}