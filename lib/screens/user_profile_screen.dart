import 'package:flutter/material.dart';
import '../widgets/avatar_with_letter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';

class UserProfileScreen extends StatelessWidget {
  final String userName;
  final String userStatus;
  final String userImageUrl;
  final String chatId;

  final String peerId;

  UserProfileScreen({
    super.key,
    required this.userName,
    required this.userStatus,
    required this.userImageUrl,
    required this.chatId,
  }) :
        peerId = _getPeerId(FirebaseAuth.instance.currentUser!.uid, chatId);

  static String _getPeerId(String currentUserId, String fullChatId) {

    final ids = fullChatId.split('_');
    return ids.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  Future<void> _setNickname(BuildContext context, String? newNickname) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not logged in.')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);
    final nicknameKey = 'nickname_$currentUserId';

    try {
      if (newNickname == null || newNickname.isEmpty) {

        await chatRef.update({
          nicknameKey: FieldValue.delete(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nickname cleared for $userName')),
        );
      } else {

        await chatRef.set({
          nicknameKey: newNickname,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nickname set to "$newNickname" for $userName')),
        );
      }
      if(Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update nickname: ${e.toString()}')),
      );
    }
  }


  void _showSetNicknameDialog(BuildContext context) {
    final controller = TextEditingController();
    final primaryColor = Theme.of(context).colorScheme.secondary;


    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBackgroundColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final hintColor = isDarkMode ? Colors.grey.shade500 : Colors.grey;
    final buttonColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(

        backgroundColor: dialogBackgroundColor,

        title: Text('Set Nickname for $userName',

            style: TextStyle(color: textColor)),

        content: TextField(
          controller: controller,

          style: TextStyle(color: textColor),

          decoration: InputDecoration(
            hintText: "Enter Nickname",

            hintStyle: TextStyle(color: hintColor),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(

              borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey),
            ),
          ),
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(

            child: Text('Cancel', style: TextStyle(color: buttonColor)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(

            child: Text('Set', style: TextStyle(color: primaryColor)),
            onPressed: () {
              _setNickname(context, controller.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('chats').doc(chatId);

    try {
      final messagesSnapshot = await chatRef.collection('messages').get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      await chatRef.delete();


      Navigator.of(context)
        ..pop()
        ..pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversation with $userName deleted successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete chat: ${e.toString()}')),
      );
    }
  }

  void _handleBlock(BuildContext context, bool currentlyBlocked) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || peerId.isEmpty) return;

    final shouldBlock = !currentlyBlocked;


    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final dialogBackgroundColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final contentColor = isDarkMode ? Colors.white70 : Colors.black87;



    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(

        backgroundColor: dialogBackgroundColor,

        title: Text(
          shouldBlock ? 'Block $userName?' : 'Unblock $userName?',

          style: TextStyle(color: textColor),
        ),
        content: Text(
          shouldBlock
              ? 'Are you sure you want to block $userName? You will not be able to send or receive messages from them.'
              : 'Are you sure you want to unblock $userName? You will be able to send and receive messages again.',

          style: TextStyle(color: contentColor),
        ),
        actions: <Widget>[

          TextButton(
            child: Text('Cancel', style: TextStyle(color: contentColor)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),


          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {

                await ChatService().updateBlockStatus(chatId, peerId, shouldBlock);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(shouldBlock ? '$userName blocked.' : '$userName unblocked.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update block status: ${e.toString()}')),
                );
              }
            },
            child: Text(
              shouldBlock ? 'Block' : 'Unblock',
              // অ্যাকশন টেক্সট কালার নিশ্চিত করা
              style: TextStyle(color: shouldBlock ? Colors.red : primaryColor),
            ),
          ),
        ],
      ),
    );
  }


  void _handleMenuSelection(BuildContext context, String result) {

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dialogBackgroundColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final contentColor = isDarkMode ? Colors.white70 : Colors.black87;

    switch (result) {
      case 'delete':
      // ডিলিট কনফার্মেশন ডায়ালগ
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(

            backgroundColor: dialogBackgroundColor,

            title: Text('Delete Conversation?', style: TextStyle(color: textColor)),
            content: Text(
              'Are you sure you want to delete all messages with $userName? This action cannot be undone and will remove the chat from your list.',
              style: TextStyle(color: contentColor),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: TextStyle(color: contentColor)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              TextButton(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deleteConversation(context);
                },
              ),
            ],
          ),
        );
        break;
      case 'block_toggle':

        break;

    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isOnline = userStatus == 'Online';
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final blockedByKey = 'blockedBy_$currentUserId';


    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [

          StreamBuilder<DocumentSnapshot>(
            stream: ChatService().getBlockStatus(chatId),
            builder: (context, snapshot) {
              bool isBlocked = snapshot.hasData && snapshot.data!.exists
                  ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})[blockedByKey] == true
                  : false;


              return _buildCustomAppBar(
                context, primaryColor, isDarkMode,
                    (ctx, result) {
                  if (result == 'block_toggle') {
                    _handleBlock(ctx, isBlocked);
                  } else {
                    _handleMenuSelection(ctx, result);
                  }
                },
                backgroundColor,
                isBlocked: isBlocked,
              );
            },
          ),

          SliverList(
            delegate: SliverChildListDelegate(
              [
                // 1. Profile Details (Pic, Name, Status)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
                  child: Column(
                    children: [
                      AvatarWithLetter(
                        imageUrl: userImageUrl,
                        userName: userName,
                        radius: 40,
                        isOnline: isOnline,
                        onlineIndicatorBackgroundColor: backgroundColor,
                      ),
                      const SizedBox(height: 8),

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
                        builder: (context, chatSnapshot) {
                          String displayedName = userName;
                          String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

                          if (chatSnapshot.hasData && currentUserId != null) {
                            final chatData = chatSnapshot.data!.data() as Map<String, dynamic>?;
                            final nicknameKey = 'nickname_$currentUserId';
                            final nickname = chatData?[nicknameKey] as String?;

                            if (nickname != null && nickname.isNotEmpty) {
                              displayedName = nickname;
                            }
                          }

                          return Text(
                            displayedName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          );
                        },
                      ),

                      Text(
                        userStatus,
                        style: TextStyle(
                          fontSize: 14,
                          color: isOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Audio/Video/Mute Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionIcon(Icons.call, 'Call', primaryColor, () {}),
                          const SizedBox(width: 30),
                          _buildActionIcon(Icons.videocam, 'Video', primaryColor, () {}),
                          const SizedBox(width: 30),
                          _buildActionIcon(Icons.notifications_off, 'Mute', primaryColor, () {}),
                        ],
                      ),
                    ],
                  ),
                ),

                Divider(color: dividerColor),

                // 2. Customization Block
                _buildSectionHeader('Customization', isDarkMode),

                _buildSettingsItem(
                    context, Icons.person_outline, 'Set Nickname', primaryColor,
                        () => _showSetNicknameDialog(context)),


                _buildSettingsItem(
                    context, Icons.clear_all, 'Clear Nickname', primaryColor,
                        () => _setNickname(context, null)),

                _buildSettingsItem(context, Icons.group_add_outlined,
                    'Create Group Chat with $userName', primaryColor, () {}),
                _buildSettingsItem(
                    context, Icons.push_pin_outlined, 'Pinned Messages', primaryColor,
                        () {}),

                Divider(color: dividerColor),

                // 3. Search in Conversation
                _buildSettingsItem(
                    context, Icons.search, 'Search in Conversation', primaryColor,
                        () {}),
                _buildSettingsItem(context, Icons.notifications_none,
                    'Notifications & Sounds', primaryColor, () {}),

                Divider(color: dividerColor),

                // 4. Privacy & Support
                _buildSectionHeader('Privacy & Support', isDarkMode),

                StreamBuilder<DocumentSnapshot>(
                  stream: ChatService().getBlockStatus(chatId),
                  builder: (context, snapshot) {
                    bool isBlocked = snapshot.hasData && snapshot.data!.exists
                        ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})[blockedByKey] == true
                        : false;

                    return _buildSettingsItem(
                      context,
                      isBlocked ? Icons.lock_open_outlined : Icons.block_outlined,
                      isBlocked ? 'Unblock' : 'Block',
                      isBlocked ? Colors.green : Colors.red,
                          () => _handleBlock(context, isBlocked),
                    );
                  },
                ),

                _buildSettingsItem(context, Icons.flag_outlined, 'Report', primaryColor, () {}),
                _buildSettingsItem(
                    context, Icons.delete_outline, 'Delete Chat', primaryColor,
                        () => _handleMenuSelection(context, 'delete')),

                // Safe Area Padding
                SizedBox(height: bottomPadding + 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  SliverAppBar _buildCustomAppBar(
      BuildContext context, Color primaryColor, bool isDarkMode, void Function(BuildContext, String) onSelect, Color backgroundColor, {required bool isBlocked}) {
    return SliverAppBar(
      backgroundColor: backgroundColor,
      pinned: true,
      elevation: 1,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Text(
        userName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
          color: isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white,
          onSelected: (String result) => onSelect(context, result),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete Conversation', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
            // Block/Unblock মেনু আইটেম
            PopupMenuItem<String>(
              value: 'block_toggle',
              child: Text(isBlocked ? 'Unblock' : 'Block', style: TextStyle(color: isBlocked ? Colors.green : Colors.red)),
            ),
            PopupMenuItem<String>(
              value: 'report',
              child: Text('Report', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, String title,
      Color primaryColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildActionIcon(
      IconData icon, String label, Color primaryColor, VoidCallback onTap) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: primaryColor, size: 24),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: primaryColor, fontSize: 12),
        ),
      ],
    );
  }
}