import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import 'journal_entry_screen.dart';
import '../widgets/mood_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/journal_list_tile.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final journalService = JournalService();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Evening,',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'User 🌙',
                        style: Theme.of(context).textTheme.displayMedium,
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
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=12'), // Placeholder
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mood Card
              const MoodCard(),
              const SizedBox(height: 16),

              // AI Insight Card
              const InsightCard(),
              const SizedBox(height: 24),

              // Recent Journals Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Journals',
                    style: Theme.of(context).textTheme.headlineMedium,
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
                        child: Text('No journals yet. Start writing!'),
                      );
                    }

                    // Display only the 3 most recent
                    final journals = snapshot.data!.take(3).toList();

                    return Column(
                      children: journals.map((journal) {
                        return GestureDetector(
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
