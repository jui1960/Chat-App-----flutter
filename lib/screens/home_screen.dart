// lib/screens/home_screen.dart (FINAL UPDATED CODE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../menu_view.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'user_status_tracker.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';

import '../widgets/avatar_with_letter.dart';
import '../widgets/group_avatar.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final firestore = FirebaseFirestore.instance;


  String _getChatId(String user1Id, String user2Id) {
    if (user1Id.compareTo(user2Id) > 0) {
      return '${user1Id}_$user2Id';
    } else {
      return '${user2Id}_$user1Id';
    }
  }


  void _startChat(String peerId, String peerName, String peerImageUrl, String userStatus) {
    if (currentUserId == null) return;

    final chatId = _getChatId(currentUserId!, peerId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          userName: peerName,
          userStatus: userStatus,
          userImageUrl: peerImageUrl,
        ),
      ),
    );
  }


  void _startGroupChat(String chatId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(
          chatId: chatId,
          groupName: groupName,
        ),
      ),
    );
  }


  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerTextColor = isDarkMode ? Colors.white : Colors.black;
    final listBackgroundColor = isDarkMode ? Theme.of(context).colorScheme.surface : Colors.white;

    if (currentUserId == null) {
      return const Center(child: Text("Please login again."));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ChatApp",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: headerTextColor),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),

                  IconButton(
                    icon: Icon(Icons.group_add_outlined, color: Theme.of(context).colorScheme.secondary),
                    onPressed: _navigateToCreateGroup,
                  ),
                ],
              )
            ],
          ),
        ),

        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: listBackgroundColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('chats')
                  .where('members', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading chats: ${snapshot.error}'));
                }

                final chatDocs = snapshot.data!.docs;

                if (chatDocs.isEmpty) {
                  return const Center(child: Text('Start a new chat from the Search screen!'));
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chatDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index].data() as Map<String, dynamic>?;
                    final chatId = chatDocs[index].id;

                    final isGroup = chatDoc?['isGroup'] ?? false;

                    // --- NESTED STREAMBUILDER for Real-Time Last Message ---
                    return StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, messageSnapshot) {
                        String lastMessage = 'Start chatting!';
                        String lastTime = '';

                        if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                          final messageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                          lastMessage = messageData['text'] ?? 'Image/File';

                          if (messageData['timestamp'] is Timestamp) {
                            final ts = messageData['timestamp'] as Timestamp;
                            final date = ts.toDate();
                            lastTime = DateFormat('h:mm a').format(date);
                          }
                        }

                        // --- A. গ্রুপ চ্যাট ডিসপ্লে ---
                        if (isGroup) {
                          final groupName = chatDoc?['name'] ?? 'Group Chat';
                          final initialsList = (chatDoc?['initialsForAvatar'] as List<dynamic>? ?? [])
                              .cast<String>();

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            // ✅ নতুন: গ্রুপ আভাটার উইজেট ব্যবহার
                            leading: GroupAvatar(
                              groupName: groupName,
                              initials: initialsList,
                              radius: 28,
                            ),
                            title: Text(groupName, style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor)),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                            ),
                            trailing: Text(lastTime,
                                style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade600 : Colors.grey)),
                            onTap: () => _startGroupChat(chatId, groupName), // ✅ গ্রুপ চ্যাট শুরু করা
                          );
                        }


                        else {
                          final members = chatDoc?['members'] as List<dynamic>?;
                          if (members == null || members.length != 2) return const SizedBox.shrink();
                          final peerId = members.firstWhere((id) => id != currentUserId);

                          // Nickname লজিক
                          final nicknameKey = 'nickname_$currentUserId';
                          final savedNickname = chatDoc?[nicknameKey] as String?;


                          // --- FutureBuilder to fetch Peer User Data ---
                          return FutureBuilder<DocumentSnapshot>(
                            future: firestore.collection('users').doc(peerId).get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(height: 80);
                              }
                              if (!userSnapshot.hasData || userSnapshot.hasError || !userSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                              final defaultUsername = userData['fullName'] ?? userData['username'] ?? 'Chat User';
                              final userImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150';

                              // ✅ ফাইনাল ডিসপ্লে নাম সেট করা
                              final displayUsername = (savedNickname != null && savedNickname.isNotEmpty)
                                  ? savedNickname
                                  : defaultUsername;

                              final isOnline = userData['isOnline'] == true;
                              final lastSeenTimestamp = userData['lastSeen'] as Timestamp?;

                              String userStatus;
                              if (isOnline) {
                                userStatus = 'Online';
                              } else if (lastSeenTimestamp != null) {
                                final time = lastSeenTimestamp.toDate();
                                userStatus = DateFormat('h:mm a').format(time);
                              } else {
                                userStatus = '';
                              }

                              // --- Final ListTile Widget (1-to-1) ---
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                leading: AvatarWithLetter(
                                  imageUrl: userImageUrl,
                                  userName: defaultUsername,
                                  isOnline: isOnline,
                                  radius: 28,
                                  onlineIndicatorBackgroundColor: listBackgroundColor,
                                ),
                                title: Text(displayUsername,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor)),
                                subtitle: Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(lastTime,
                                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade600 : Colors.grey)),
                                    const SizedBox(height: 4),
                                    if (userStatus.isNotEmpty)
                                      Text(
                                          userStatus,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isOnline ? Colors.green : Colors.grey
                                          )
                                      ),
                                  ],
                                ),
                                onTap: () => _startChat(peerId, defaultUsername, userImageUrl, userStatus),
                              );
                            },
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<Widget> _widgetOptions = <Widget>[
    const ChatsView(),
    const MenuView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0F5F8);

    return UserStatusTracker(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'Menu',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: isDarkMode ? Colors.white60 : Colors.grey,
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDarkMode ? const Color(0xFF1E2733) : Colors.white,
        ),
      ),
    );
  }
}