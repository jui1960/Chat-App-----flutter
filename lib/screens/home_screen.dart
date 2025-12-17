// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/menu_view.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/search_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/avatar_with_letter.dart';

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
                    icon: Icon(Icons.exit_to_app, color: Theme.of(context).colorScheme.secondary),
                    onPressed: _logout,
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
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading users: ${snapshot.error}'));
                }

                final allUsers = snapshot.data!.docs
                    .where((doc) => doc.id != currentUserId)
                    .toList();

                if (allUsers.isEmpty) {
                  return const Center(child: Text('You are the only user, start inviting friends!'));
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allUsers.length,
                  separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 80,
                      endIndent: 10,
                      color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFF1F1F1)),
                  itemBuilder: (context, index) {
                    final userData = allUsers[index].data() as Map<String, dynamic>;
                    final peerId = allUsers[index].id;

                    final username = userData['fullName'] ?? userData['username'] ?? 'Chat User';
                    final userImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150';

                    final isOnline = userData['isOnline'] == true;
                    final lastSeenTimestamp = userData['lastSeen'] as Timestamp?;

                    String userStatus;
                    if (isOnline) {
                      userStatus = 'Online';
                    } else if (lastSeenTimestamp != null) {
                      final time = lastSeenTimestamp.toDate();
                      userStatus = 'Last seen ${DateFormat('h:mm a').format(time)}';
                    } else {
                      userStatus = 'Offline';
                    }

                    final chatId = _getChatId(currentUserId!, peerId);

                    // --- NESTED STREAMBUILDER for Real-Time Last Message ---
                    return StreamBuilder<QuerySnapshot>(
                      // Real-time stream to listen for changes in the 'messages' subcollection
                      stream: FirebaseFirestore.instance
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
                          // মেসেজ লোড হলে
                          final messageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                          lastMessage = messageData['text'] ?? 'Image/File';

                          if (messageData['timestamp'] is Timestamp) {
                            final ts = messageData['timestamp'] as Timestamp;
                            final date = ts.toDate();
                            lastTime = DateFormat('h:mm a').format(date);
                          }
                        }

                        // --- Final ListTile Widget ---
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          leading: AvatarWithLetter(
                            imageUrl: userImageUrl,
                            userName: username,
                            isOnline: isOnline,
                            radius: 28,
                            onlineIndicatorBackgroundColor: listBackgroundColor,
                          ),
                          title: Text(username,
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
                              Text(userStatus,
                                  style: TextStyle(fontSize: 12, color: isOnline ? Colors.green : Colors.grey)),
                            ],
                          ),
                          onTap: () => _startChat(peerId, username, userImageUrl, userStatus),
                        );
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

    return Scaffold(
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
    );
  }
}