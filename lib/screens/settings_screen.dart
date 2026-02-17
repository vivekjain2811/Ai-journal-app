import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

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

  bool _notificationsEnabled = false;
  int _frequencyMinutes = 120; // Default 2 hours (120 min)
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('reminders_enabled') ?? false;
      _frequencyMinutes = prefs.getInt('reminder_interval') ?? 120;
    });
  }

   Widget _buildReminderSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Daily Reminders'),
          subtitle: Text(_notificationsEnabled ? 'Active: Every ${_getFrequencyLabel(_frequencyMinutes)}' : 'Disabled'),
          secondary: Icon(
             _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
             color: _notificationsEnabled ? Theme.of(context).primaryColor : Colors.grey,
          ),
          value: _notificationsEnabled,
          onChanged: (bool value) async {
            if (value) {
              final granted = await _notificationService.requestPermissions();
              if (granted) {
                await _notificationService.scheduleReminders(intervalMinutes: _frequencyMinutes);
                setState(() => _notificationsEnabled = true);
              } else {
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permission required for reminders')),
                    );
                 }
              }
            } else {
              await _notificationService.cancelReminders();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('reminders_enabled', false);
              setState(() => _notificationsEnabled = false);
            }
          },
        ),
        if (_notificationsEnabled)
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
             child: Row(
               children: [
                 const Text('Frequency: '),
                 const SizedBox(width: 16),
                 Expanded(
                   child: DropdownButton<int>(
                     isExpanded: true,
                     value: _frequencyMinutes,
                     items: const [
                       DropdownMenuItem(value: 2, child: Text('Every 2 Minutes (Test)')),
                       DropdownMenuItem(value: 60, child: Text('Every 1 Hour')),
                       DropdownMenuItem(value: 120, child: Text('Every 2 Hours')),
                       DropdownMenuItem(value: 240, child: Text('Every 4 Hours')),
                       DropdownMenuItem(value: 300, child: Text('Every 5 Hours')),
                     ],
                     onChanged: (int? newValue) async {
                       if (newValue != null) {
                         setState(() => _frequencyMinutes = newValue);
                         await _notificationService.scheduleReminders(intervalMinutes: newValue);
                       }
                     },
                   ),
                 ),
               ],
             ),
           ),
        if (_notificationsEnabled)
           Padding(
             padding: const EdgeInsets.only(top: 10.0),
             child: Center(
               child: TextButton.icon(
                 onPressed: () async {
                   await NotificationService().showInstantNotification();
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Sent test notification')),
                   );
                 },
                 icon: const Icon(Icons.notifications_active),
                 label: const Text('Send Instant Test Notification'),
               ),
             ),
           ),
        if (_notificationsEnabled)
           Padding(
             padding: const EdgeInsets.only(top: 10.0),
             child: Center(
               child: TextButton.icon(
                 onPressed: () async {
                   final now = DateTime.now();
                   // Re-configure to be safe
                   await NotificationService().configureLocalTimeZone();
                   
                   final tzNow = tz.TZDateTime.now(tz.local);
                   final offset = tzNow.timeZoneOffset;
                   
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'TZ Name: ${tz.local.name}\n'
                          'Device Time: ${now.hour}:${now.minute}:${now.second}\n'
                          'TZ Time: ${tzNow.hour}:${tzNow.minute}:${tzNow.second}\n'
                          'Offset: ${offset.inHours}h ${offset.inMinutes.remainder(60)}m'
                        ),
                        duration: const Duration(seconds: 10),
                      ),
                    );
                   }
                 },
                 icon: const Icon(Icons.access_time),
                 label: const Text('Check Timezone Info'),
               ),
             ),
           ),
      ],
    );
  }

  String _getFrequencyLabel(int minutes) {
    if (minutes < 60) return '$minutes mins';
    return '${minutes ~/ 60} hours';
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
              
              // REMINDER SETTINGS - FIXED MISSING CALL
              _buildReminderSection(),

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
