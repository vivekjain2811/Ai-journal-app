import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../widgets/journal_list_tile.dart';
import '../services/journal_service.dart';
import 'journal_entry_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final JournalService _journalService = JournalService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Journals'),
            Tab(text: 'AI Journals'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  return const Center(child: Text('No journals found directly.'));
                }

                final allJournals = snapshot.data!;
                // Filter by search if needed (client-side for now)
                final searchTerm = _searchController.text.toLowerCase();
                final filteredJournals = searchTerm.isEmpty
                    ? allJournals
                    : allJournals
                        .where((j) =>
                            j.title.toLowerCase().contains(searchTerm) ||
                            j.content.toLowerCase().contains(searchTerm))
                        .toList();
                
                // TODO: 'isAI' is not yet in the model, assuming all are general for now or filtered by logic
                // For this implementation, both tabs will show same data or we can filter if we add isAI field later.
                // Or maybe 'AI Journals' are ones with a specific tag? 
                // For now, let's just show all in 'All Journals' and maybe empty or same in 'AI Journals' until defined.
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJournalList(filteredJournals),
                    const Center(child: Text('AI Journals feature coming soon')), 
                  ],
                );
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
          onDismissed: (direction) {
            _journalService.deleteJournal(journal.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${journal.title} deleted')),
            );
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
