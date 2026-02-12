import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? photoUrl;
  final String? motto;
  final String? phoneNumber;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.photoUrl,
    this.motto,
    this.phoneNumber,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'motto': motto,
      'phoneNumber': phoneNumber,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      photoUrl: map['photoUrl'],
      motto: map['motto'],
      phoneNumber: map['phoneNumber'],
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}
