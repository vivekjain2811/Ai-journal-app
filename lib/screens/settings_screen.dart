import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

import '../models/user_model.dart';
import '../theme/theme_provider.dart';
import '../widgets/gradient_scaffold.dart';
import 'help_support_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_security_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {


  @override
  void initState() {
    super.initState();

  }





  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final UserService userService = UserService();

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: user != null ? userService.getUserProfile(user.uid) : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final userData = snapshot.data;

          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (bool value) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                },
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Account Settings'),
                subtitle: const Text('Edit profile & details'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                   Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: userData),
                      ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy & Security'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacySecurityScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
