

import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatusTracker extends StatefulWidget {
  const UserStatusTracker({super.key, required this.child});
  final Widget child;

  @override
  State<UserStatusTracker> createState() => _UserStatusTrackerState();
}

class _UserStatusTrackerState extends State<UserStatusTracker> with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _setUserStatus(isOnline: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_currentUser != null) {
      _setUserStatus(isOnline: false);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentUser = _auth.currentUser;
    if (_currentUser == null) return;

    if (state == AppLifecycleState.resumed) {
      _setUserStatus(isOnline: true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _setUserStatus(isOnline: false);
    }
  }

  void _setUserStatus({required bool isOnline}) {
    if (_currentUser == null) return;

    final userRef = _firestore.collection('users').doc(_currentUser!.uid);

    final data = {
      'isOnline': isOnline,
      if (!isOnline) 'lastSeen': Timestamp.now(),
    };

    userRef.set(data, SetOptions(merge: true)).catchError((error) {
      debugPrint("Failed to update status: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}