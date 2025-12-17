import 'package:flutter/material.dart';

class AvatarWithLetter extends StatelessWidget {
  // imageUrl এবং userName-কে অবশ্যই non-nullable String হতে হবে।
  // কল করার সময় null এলে, calling site-এ ?? '' ব্যবহার করতে হবে।
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

  // Determines if the URL is a placeholder/default URL
  // এটি পরীক্ষা করে যে URL খালি, নাকি একটি ডিফল্ট URL।
  bool _isImageValid(String url) {
    // URL যদি খালি হয় (''), তবে এটি false দেবে।
    // ফলে Text Avatar দেখাবে।
    return url.isNotEmpty && url != 'https://via.placeholder.com/150';
  }

  // Gets the first capital letter
  String _getFirstLetter(String name) {
    if (name.isEmpty) return '?';
    // নামের প্রথম অক্ষরটি বড় হাতের অক্ষরে দেখাবে
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // এখানে কোনো পরিবর্তন দরকার নেই, কারণ লজিক ঠিক আছে
    final bool useImage = _isImageValid(imageUrl);
    final String firstLetter = _getFirstLetter(userName);

    // List background color for border of the online indicator
    final listBackgroundColor = onlineIndicatorBackgroundColor ?? Theme.of(context).colorScheme.surface;

    // The main Avatar widget (either NetworkImage or Letter)
    final Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      backgroundImage: useImage
          ? NetworkImage(imageUrl) // এখানে এখন error দেবে না, কারণ imageUrl non-empty
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

    // If an online indicator is requested, wrap the avatar in a Stack
    if (isOnline) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.43, // Size relative to radius
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