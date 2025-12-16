// lib/screens/search_screen.dart (Updated with Firebase/Firestore Search Logic)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/screens/chat_screen.dart'; // নিশ্চিত করুন যে এই পাথটি সঠিক

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Firestore থেকে সার্চ রেজাল্ট ধরে রাখার জন্য FutureBuilder ব্যবহার করা হচ্ছে
  Future<QuerySnapshot>? _searchResults;

  // বর্তমানে লগইন থাকা ইউজারের আইডি
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  void _searchUsers(String query) {
    // সার্চ টেক্সট খালি থাকলে, রেজাল্ট মুছে দাও
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    // কোয়েরি স্ট্রিংকে lowercase এ পরিবর্তন করা, কারণ আমরা ডেটাবেসে username-কে lowercase এ সেভ করব
    // Note: If you don't save a lowercase username field, this query might fail.
    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      // Firestore query: 'users' কালেকশনে সার্চ করা
      // আমরা ধরে নিচ্ছি আপনার users কালেকশনে 'username' ফিল্ড আছে।
      // \uf8ff এই ইউনিকোড অক্ষরটি ব্যবহার করা হয় একটি স্ট্রিং দিয়ে শুরু হওয়া সমস্ত ডকুমেন্ট পেতে
      _searchResults = FirebaseFirestore.instance
          .collection('users')
      // এখানে 'username' ফিল্ডটি ব্যবহার করা হচ্ছে। (Ensure you have this field in Firestore)
          .where('username', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('username', isLessThanOrEqualTo: lowerCaseQuery + '\uf8ff')
          .get();
    });
  }

  // দুটি ইউজার আইডি ব্যবহার করে একটি ইউনিক চ্যাট আইডি তৈরি করা
  String _getChatId(String user1Id, String user2Id) {
    // বর্ণানুক্রমিকভাবে আইডি দুটিকে সাজানো, যাতে চ্যাট আইডি সবসময় একই থাকে
    if (user1Id.compareTo(user2Id) > 0) {
      return '${user1Id}_$user2Id';
    } else {
      return '${user2Id}_$user1Id';
    }
  }

  void _startChat(String peerId, String peerName, String peerImageUrl) {
    // 1. চ্যাট আইডি তৈরি করা
    final chatId = _getChatId(_currentUserId, peerId);

    // 2. ChatScreen-এ নেভিগেট করা
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
    return Scaffold(
      appBar: AppBar(
        // The AppBar acts as the search bar title
        title: TextField(
          controller: _searchController,
          autofocus: true, // স্ক্রিন খুললেই কার্সর চলে আসবে
          decoration: InputDecoration(
            hintText: 'Search user by username...',
            border: InputBorder.none,
            // Hint text color based on theme
            hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
          ),
          onChanged: _searchUsers, // টাইপ করার সাথে সাথে সার্চ শুরু হবে
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              // সার্চ ক্লিয়ার করা
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (_searchController.text.isEmpty) {
            return const Center(child: Text('Start typing a username to search.'));
          }

          // ডেটা না থাকলে বা রেজাল্ট খালি থাকলে
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found with that name.'));
          }

          // নিজের আইডিকে সার্চ রেজাল্ট থেকে বাদ দেওয়া
          final users = snapshot.data!.docs.where((doc) => doc.id != _currentUserId).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users found.'));
          }

          // সার্চ রেজাল্ট লিস্ট তৈরি করা
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              // ডেটাবেস থেকে ইউজারনেম এবং ইমেজ ইউআরএল লোড করা
              final username = userData['username'] ?? 'Chat User';
              final userImageUrl = userData['imageUrl'] ?? 'https://via.placeholder.com/150';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userImageUrl),
                ),
                title: Text(username),
                subtitle: Text(userData['email'] ?? 'User ID: $userId'),
                onTap: () => _startChat(userId, username, userImageUrl),
              );
            },
          );
        },
      ),
    );
  }
}