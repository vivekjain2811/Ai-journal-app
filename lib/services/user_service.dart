import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get User Profile
  Stream<UserModel?> getUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromSnapshot(snapshot);
      }
      return null;
    });
  }

  // Create or Update User Profile
  Future<void> updateUserProfile(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Upload Profile Image
  Future<String> uploadProfileImage(File image, String uid) async {
    try {
      // Create a reference to the location you want to upload to in firebase
      final Reference ref = _storage.ref().child('user_images').child('$uid.jpg');

      // Upload the file to firebase
      final UploadTask uploadTask = ref.putFile(image);

      // Waits till the file is uploaded then stores the download url
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Error uploading image: $e';
    }
  }
}
