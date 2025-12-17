import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatusTracker extends WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  UserStatusTracker() {
    // WidgetsBinding-এ Observer হিসেবে নিজেকে যোগ করা
    WidgetsBinding.instance.addObserver(this);

    // অ্যাপ চালু হওয়ার সাথে সাথেই স্ট্যাটাস "Online" করা
    if (_userId != null) {
      _updateUserStatus(true);
    }
  }

  // যখন অ্যাপের লাইফসাইকেল স্টেট পরিবর্তন হয়
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_userId == null) return;

    if (state == AppLifecycleState.resumed) {
      // অ্যাপ ফোরগ্রাউন্ডে আসলে (খুললে)
      _updateUserStatus(true);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // অ্যাপ ব্যাকগ্রাউন্ডে গেলে বা বন্ধ হলে
      _updateUserStatus(false);
    }
  }

  // Firestore-এ স্ট্যাটাস আপডেট করার মূল ফাংশন
  void _updateUserStatus(bool isOnline) {
    _firestore.collection('users').doc(_userId).update({
      'isOnline': isOnline,
      // শেষ কখন দেখা গেছে তার রেকর্ড
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((error) {
      // যদি Firestore-এ ডেটা সেভ করতে কোনো সমস্যা হয় (যেমন 'users' কালেকশন না থাকলে)
      print('Failed to update user status: $error');
    });
  }
}