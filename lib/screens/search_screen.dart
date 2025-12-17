// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/chat_screen.dart';
// ইমপোর্ট পাথ সংশোধন করা হলো (widgets ফোল্ডার ধরে নেওয়া হয়েছে)
import '../widgets/avatar_with_letter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Future<QuerySnapshot>? _searchResults;

  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void _searchUsers(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      _searchResults = FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('username', isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
          .get();
    });
  }

  String _getChatId(String user1Id, String user2Id) {
    if (user1Id.compareTo(user2Id) > 0) {
      return '${user1Id}_$user2Id';
    } else {
      return '${user2Id}_$user1Id';
    }
  }

  void _startChat(String peerId, String peerName, String peerImageUrl) {
    final chatId = _getChatId(_currentUserId, peerId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          userName: peerName,
          userStatus: 'Offline', // You can load actual status here later
          userImageUrl: peerImageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final hintTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final iconColor = isDarkMode ? Colors.white : Colors.black;
    final listTileTextColor = primaryTextColor; // Use primary text color for list items

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: iconColor), // Set back button/action icon color
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search user by username...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: hintTextColor), // Apply custom hint color
          ),
          onChanged: _searchUsers,
          style: TextStyle(color: primaryTextColor), // Apply custom input text color
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.clear, color: iconColor),
            onPressed: () {
              _searchController.clear();
              _searchUsers('');
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _searchController.text.isNotEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: primaryTextColor)));
          }
          if (_searchController.text.isEmpty) {
            return Center(child: Text('Start typing a username to search.', style: TextStyle(color: primaryTextColor)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No users found with that name.', style: TextStyle(color: primaryTextColor)));
          }

          final users = snapshot.data!.docs.where((doc) => doc.id != _currentUserId).toList();

          if (users.isEmpty) {
            return Center(child: Text('No other users found.', style: TextStyle(color: primaryTextColor)));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              final username = userData['fullName'] ?? userData['username'] ?? 'Chat User';
              final userImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150';

              return ListTile(
                leading: AvatarWithLetter(
                  imageUrl: userImageUrl,
                  userName: username,
                  radius: 28,
                  isOnline: false,
                ),
                title: Text(
                  username,
                  style: TextStyle(color: listTileTextColor, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Tap to start chat',
                  style: TextStyle(color: hintTextColor),
                ),
                onTap: () => _startChat(userId, username, userImageUrl),
              );
            },
          );
        },
      ),
    );
  }
}