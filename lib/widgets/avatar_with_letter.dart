import 'package:flutter/material.dart';

class AvatarWithLetter extends StatelessWidget {
  final String imageUrl;
  final String userName;
  final double radius;
  final bool isOnline;
  final Color? onlineIndicatorBackgroundColor;

  const AvatarWithLetter({
    super.key,
    required this.imageUrl,
    required this.userName,
    this.radius = 28,
    this.isOnline = false,
    this.onlineIndicatorBackgroundColor,
  });

  bool _isImageValid(String url) {
    return url.isNotEmpty && url != 'https://via.placeholder.com/150';
  }

  String _getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool useImage = _isImageValid(imageUrl);
    final String firstLetter = _getFirstLetter(userName);

    final listBackgroundColor = onlineIndicatorBackgroundColor ?? Theme.of(context).colorScheme.surface;

    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      backgroundImage: useImage
          ? NetworkImage(imageUrl)
          : null,
      child: useImage
          ? null
          : Text(
        firstLetter,
        style: TextStyle(
          fontSize: radius * 0.9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (isOnline) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.43,
              height: radius * 0.43,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: listBackgroundColor, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}