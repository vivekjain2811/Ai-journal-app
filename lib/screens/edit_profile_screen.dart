import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _mottoController;
  late TextEditingController _phoneController;
  File? _imageFile;
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _mottoController = TextEditingController(text: widget.user?.motto ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _currentPhotoUrl = widget.user?.photoUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _mottoController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final int sizeInBytes = await image.length();
      final double sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl = _currentPhotoUrl;
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) throw 'User not authenticated';

      // Upload image if selected
      if (_imageFile != null) {
        photoUrl = await _userService.uploadProfileImage(_imageFile!, currentUser.uid);
      }

      final updatedUser = UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        username: _usernameController.text.trim(),
        motto: _mottoController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      await _userService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_currentPhotoUrl != null
                              ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                              : null),
                      child: _imageFile == null && _currentPhotoUrl == null
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              CustomTextField(
                controller: _usernameController,
                label: 'Values',
                hint: 'Enter your username',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _mottoController,
                label: 'Motto',
                hint: 'Your personal motto',
                prefixIcon: Icons.format_quote,
              ),
               const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Save Button
              if (_isLoading)
                const CircularProgressIndicator()
              else
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
