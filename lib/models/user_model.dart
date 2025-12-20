import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? fullName;
  final String? imageUrl;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.fullName,
    this.imageUrl,
    this.isOnline = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'],
      fullName: data['fullName'],
      imageUrl: data['imageUrl'],
      isOnline: data['isOnline'] ?? false,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'],
      fullName: data['fullName'],
      imageUrl: data['imageUrl'],
      isOnline: data['isOnline'] ?? false,
    );
  }

  String get displayName => fullName ?? username ?? 'User';
}