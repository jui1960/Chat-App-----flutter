// lib/screens/home_screen.dart (FINAL UPDATED CODE)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/menu_view.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/search_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/avatar_with_letter.dart';
import 'user_status_tracker.dart';


class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final firestore = FirebaseFirestore.instance; // ✅ Firestore ইনস্ট্যান্স যোগ করা হলো

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

  void _navigateToCreateGroup() {
    // TODO: Implement navigation to the screen where users can select members and create a group.
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigate to Group Creation Screen'))
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
            // ✅ FIX 1: users কালেকশনের পরিবর্তে chats কালেকশন স্ট্রিম করা হলো
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('chats')
                  .where('members', arrayContains: currentUserId) // শুধুমাত্র currentUserId যে চ্যাটগুলোর member
              // .orderBy('lastMessageTimestamp', descending: true) // যদি 'lastMessageTimestamp' ফিল্ড থাকে
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

                // ✅ FIX 2: ListTiles তৈরি করার জন্য FutureBuilder ব্যবহার করা হলো
                // কারণ প্রত্যেক chatDoc এর জন্য peerId এবং তার userData আনতে হবে
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chatDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    final chatDoc = chatDocs[index].data() as Map<String, dynamic>?;
                    final chatId = chatDocs[index].id;

                    // peerId বের করা
                    final members = chatDoc?['members'] as List<dynamic>?;
                    if (members == null || members.length != 2) return const SizedBox.shrink();
                    final peerId = members.firstWhere((id) => id != currentUserId);

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
                        final username = userData['fullName'] ?? userData['username'] ?? 'Chat User';
                        final userImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150';

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

                        // --- NESTED STREAMBUILDER for Real-Time Last Message (আগের মতো) ---
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
                            } else {
                              // যদি কোনো মেসেজ না থাকে (যেমন সার্চ স্ক্রিন থেকে চ্যাট শুরু করার জন্য তৈরি হওয়া ফাঁকা ডক)
                              // আপনি চাইলে এটি দেখাতে পারেন ('Start chatting!') অথবা অদৃশ্য করতে পারেন (return const SizedBox.shrink())
                            }

                            // --- Final ListTile Widget ---
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                              onTap: () => _startChat(peerId, username, userImageUrl, userStatus),
                            );
                          },
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