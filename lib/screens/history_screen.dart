import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_list_tile.dart';
import '../services/journal_service.dart';
import '../services/notification_service.dart';
import '../widgets/gradient_scaffold.dart';
import 'journal_entry_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final JournalService _journalService = JournalService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search journals...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? _journalService.getJournals(FirebaseAuth.instance.currentUser!.uid)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No journals found.'));
                }

                final allJournals = snapshot.data!;
                final searchTerm = _searchController.text.toLowerCase();
                final filteredJournals = searchTerm.isEmpty
                    ? allJournals
                    : allJournals
                        .where((j) =>
                            j.title.toLowerCase().contains(searchTerm) ||
                            j.content.toLowerCase().contains(searchTerm))
                        .toList();
                
                return _buildJournalList(filteredJournals);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalList(List<JournalEntry> journals) {
    if (journals.isEmpty) {
      return const Center(child: Text('No journals found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: journals.length,
      itemBuilder: (context, index) {
        final journal = journals[index];
        return Dismissible(
          key: Key(journal.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) async {
            await _journalService.deleteJournal(journal.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${journal.title} deleted')),
              );
            }

            // Check if the deleted entry was from today
            final now = DateTime.now();
            final entryDate = journal.createdAt;
            final isToday = entryDate.year == now.year &&
                entryDate.month == now.month &&
                entryDate.day == now.day;

            if (isToday) {
              // Count remaining today-entries from the in-memory list
              // (excluding the one we just deleted)
              final remainingToday = journals.where((j) {
                if (j.id == journal.id) return false; // skip deleted one
                return j.createdAt.year == now.year &&
                    j.createdAt.month == now.month &&
                    j.createdAt.day == now.day;
              }).length;

              if (remainingToday == 0) {
                await NotificationService().resumeReminders();
              }
            }
          },
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
      },
    );
  }
}
