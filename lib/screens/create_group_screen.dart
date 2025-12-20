import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/group_service.dart';
import '../widgets/avatar_with_letter.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController();
  final List<UserModel> _selectedMembers = [];
  final _firestore = FirebaseFirestore.instance;
  final _currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  void _toggleMemberSelection(UserModel user) {
    setState(() {
      if (_selectedMembers.any((m) => m.uid == user.uid)) {
        _selectedMembers.removeWhere((m) => m.uid == user.uid);
      } else {
        _selectedMembers.add(user);
      }
    });
  }

  void _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty || _selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a group name and at least one other member.')),
      );
      return;
    }

    try {
      await GroupService().createGroup(
        groupName: groupName,
        members: _selectedMembers,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group "$groupName" created successfully!')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.secondary;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // A. গ্রূপের নাম লেখার সেকশন
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g., Team Coders',
                labelStyle: TextStyle(color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),

          // B. সার্চ এবং নির্বাচিত মেম্বার সেকশন
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('To:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // নির্বাচিত সদস্যদের ট্যাগ
                      ..._selectedMembers.map((user) => Chip(
                        label: Text(user.displayName),
                        backgroundColor: primaryColor.withOpacity(0.1),
                        deleteIcon: Icon(Icons.close, size: 16, color: primaryColor),
                        onDeleted: () => _toggleMemberSelection(user),
                      )).toList(),

                      // সার্চ ফিল্ড
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search friends...',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(bottom: 5, top: 8),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // C. ইউজার লিস্ট (সার্চ ফিল্টার সহ)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('uid', isNotEqualTo: _currentUserUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No other users found in the system.'));
                }

                final users = snapshot.data!.docs
                    .map((doc) => UserModel.fromDocument(doc))
                    .toList();

                final searchQuery = _searchController.text.toLowerCase();

                final filteredUsers = users.where((user) {
                  // displayName গেটারটি নন-নাল ভ্যালু নিশ্চিত করে
                  final displayName = user.displayName.toLowerCase();

                  // email এবং username নাল হতে পারে, তাই নাল সেফটি অপারেটর ব্যবহার করা হয়েছে
                  final email = user.email?.toLowerCase() ?? '';
                  final username = user.username?.toLowerCase() ?? '';

                  final matchesSearch = displayName.contains(searchQuery) ||
                      email.contains(searchQuery) ||
                      username.contains(searchQuery);

                  return matchesSearch &&
                      !_selectedMembers.any((m) => m.uid == user.uid);
                }).toList();

                if (filteredUsers.isEmpty && searchQuery.isNotEmpty) {
                  return Center(child: Text('No users matching "$searchQuery" found.'));
                } else if (filteredUsers.isEmpty && searchQuery.isEmpty) {
                  // সার্চ বক্স খালি থাকা সত্ত্বেও যদি কোন ইউজার না আসে
                  return const Center(child: Text('No users available to add.'));
                }


                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: AvatarWithLetter(
                        imageUrl: user.imageUrl ?? '',
                        userName: user.displayName,
                        radius: 20,
                        isOnline: user.isOnline,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(user.email),
                      trailing: Checkbox(
                        value: _selectedMembers.any((m) => m.uid == user.uid),
                        onChanged: (bool? value) => _toggleMemberSelection(user),
                        activeColor: primaryColor,
                      ),
                      onTap: () => _toggleMemberSelection(user),
                    );
                  },
                );
              },
            ),
          ),

          // D. Create Group Button
          Padding(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 8.0,
              bottom: bottomPadding > 0 ? bottomPadding : 8.0,
            ),
            child: ElevatedButton(
              onPressed: _selectedMembers.length >= 1 ? _createGroup : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 5,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Create Group',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}