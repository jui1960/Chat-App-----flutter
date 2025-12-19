// lib/services/group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class GroupService {
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser!;

  // নতুন গ্রুপ তৈরি করে Firestore এ সেভ করবে
  Future<void> createGroup({
    required String groupName,
    required List<UserModel> members,
  }) async {
    // বর্তমান ব্যবহারকারীকে মেম্বার লিস্টে যুক্ত করা হলো
    final allMembers = members.map((u) => u.uid).toList();
    if (!allMembers.contains(_currentUser.uid)) {
      allMembers.add(_currentUser.uid);
    }

    // প্রথম তিনজন সদস্যের নামের প্রথম অক্ষর দিয়ে আভাটার তৈরি করার জন্য আইডি সেভ
    final List<String> initialsForAvatar = [];
    final allMembersDetails = [
      ...members,
      UserModel(uid: _currentUser.uid, email: _currentUser.email ?? '', fullName: _currentUser.displayName)
    ];

    // প্রথম তিনজন সদস্যের নাম বের করা (আভাটার জন্য)
    for (int i = 0; i < 3 && i < allMembersDetails.length; i++) {
      String name = allMembersDetails[i].fullName ?? allMembersDetails[i].username ?? 'U';
      if (name.isNotEmpty) {
        initialsForAvatar.add(name[0].toUpperCase());
      }
    }


    final newGroup = {
      'name': groupName,
      'members': allMembers,
      'adminId': _currentUser.uid,
      'createdAt': Timestamp.now(),
      'lastMessage': '',
      'lastMessageAt': Timestamp.now(),
      'isGroup': true,
      'initialsForAvatar': initialsForAvatar.isNotEmpty ? initialsForAvatar : ['G'],
    };

    // 'chats' কালেকশনে নতুন ডকুমেন্ট তৈরি করা
    await _firestore.collection('chats').add(newGroup);
  }
}