import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/journal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  bool _isAutoPaused = false;
  int _frequencyMinutes = 120; // Default 2 hours (120 min)
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnabled = prefs.getBool('reminders_enabled') ?? false;
    final loadedFrequency = prefs.getInt('reminder_interval') ?? 120;

    // Check local flag first
    final lastJournalDate = prefs.getString('last_journal_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    bool journaledToday = (lastJournalDate == today);

    // If local flag says "journaled today", verify against Firestore
    // in case journals were deleted (clears stale state)
    if (journaledToday) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final actuallyJournaled = await JournalService().hasJournaledToday(user.uid);
          if (!actuallyJournaled) {
            // Journals were deleted — clear stale flags and resume
            journaledToday = false;
            await prefs.remove('last_journal_date');
            await prefs.setBool('reminders_auto_paused', false);
            // Resume reminders if they were enabled
            if (savedEnabled) {
              await _notificationService.scheduleReminders(intervalMinutes: loadedFrequency);
            }
          }
        } catch (e) {
          debugPrint('Error checking journal status: $e');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _frequencyMinutes = loadedFrequency;
      if (savedEnabled && journaledToday) {
        _notificationsEnabled = false;
        _isAutoPaused = true;
      } else {
        _notificationsEnabled = savedEnabled;
        _isAutoPaused = false;
      }
    });
  }

   Widget _buildReminderSection() {
    String subtitle;
    if (_isAutoPaused) {
      subtitle = 'Paused — you already journaled today ✅';
    } else if (_notificationsEnabled) {
      subtitle = 'Active: Every ${_getFrequencyLabel(_frequencyMinutes)}';
    } else {
      subtitle = 'Disabled';
    }

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Daily Reminders'),
          subtitle: Text(subtitle),
          secondary: Icon(
             _isAutoPaused
                 ? Icons.notifications_paused
                 : (_notificationsEnabled ? Icons.notifications_active : Icons.notifications_off_outlined),
             color: _isAutoPaused
                 ? Colors.orange
                 : (_notificationsEnabled ? Theme.of(context).primaryColor : Colors.grey),
          ),
          value: _notificationsEnabled,
          onChanged: (bool value) async {
            if (value) {
              // Check if already journaled — prevent re-enable
              if (_isAutoPaused) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You already journaled today! Reminders will resume tomorrow.')),
                  );
                }
                return;
              }
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
              await prefs.setBool('reminders_auto_paused', false);
              setState(() {
                _notificationsEnabled = false;
                _isAutoPaused = false;
              });
            }
          },
        ),
        if (_notificationsEnabled || _isAutoPaused)
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
                       DropdownMenuItem(value: 120, child: Text('Every 2 Hours')),
                       DropdownMenuItem(value: 180, child: Text('Every 3 Hours')),
                       DropdownMenuItem(value: 300, child: Text('Every 5 Hours')),
                     ],
                     onChanged: _isAutoPaused ? null : (int? newValue) async {
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
