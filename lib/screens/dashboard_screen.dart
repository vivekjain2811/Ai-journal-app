import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/gradient_scaffold.dart';
import '../models/journal_entry.dart';
import '../models/user_model.dart';
import '../services/journal_service.dart';
import '../services/user_service.dart';
import 'journal_entry_screen.dart';
import '../widgets/mood_card.dart';
import '../widgets/mood_calendar.dart';

import '../widgets/journal_list_tile.dart';
import '../widgets/action_card.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final journalService = JournalService();

    return GradientScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (user != null)
                StreamBuilder<UserModel?>(
                  stream: UserService().getUserProfile(user.uid),
                  builder: (context, snapshot) {
                    final userData = snapshot.data;
                    final displayName = userData?.username?.isNotEmpty == true 
                        ? userData!.username! 
                        : (user.displayName ?? 'User');
                    final photoUrl = userData?.photoUrl ?? user.photoURL;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date or Greeting
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              () {
                                final hour = DateTime.now().hour;
                                if (hour >= 5 && hour < 12) {
                                  return 'Good Morning,';
                                } else if (hour >= 12 && hour < 17) {
                                  return 'Good Afternoon,';
                                } else if (hour >= 17 && hour < 21) {
                                  return 'Good Evening,';
                                } else {
                                  return 'Good Night,'; // Late night
                                }
                              }(),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: photoUrl != null
                                  ? NetworkImage(photoUrl)
                                  : const NetworkImage('https://i.pravatar.cc/150?img=12'),
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Mood Calendar (Weekly view by default implies "Check-in")
              const MoodCalendar(),
              const SizedBox(height: 32),
              
              // Mood Card (Interactive)
               const MoodCard(),
              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Start a session',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Action Cards Row
               ActionCard(
                  title: 'New Journal',
                  subtitle: 'Write about your day',
                  icon: Icons.edit_note_rounded, // Assuming material icons
                  color: const Color(0xFF6C63FF), // Purple accent
                  isLarge: true,
                  onTap: () {
                     // Navigate to create new journal
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JournalEntryScreen(),
                        ),
                      );
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ActionCard(
                      title: 'Insights',
                      subtitle: 'Weekly analysis', // Fixed: was "Weekly analysis"
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF4CAF50), // Green
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionCard(
                      title: 'History',
                      subtitle: 'Past entries',
                      icon: Icons.history_rounded,
                      color: const Color(0xFFFFA726), // Orange
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              // Recent Journals Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Journals',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                       fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Recent Journals List
              if (user != null)
                StreamBuilder<List<JournalEntry>>(
                  stream: journalService.getJournals(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No journals yet. Start writing!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    // Display only the 3 most recent
                    final journals = snapshot.data!.take(3).toList();

                    return Column(
                      children: journals.map((journal) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GestureDetector(
                            onTap: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => JournalEntryScreen(entry: journal),
                                ),
                              );
                            },
                            child: JournalListTile(
                              title: journal.title,
                              preview: journal.content,
                              date: journal.createdAt,
                              moodEmoji: journal.mood,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
