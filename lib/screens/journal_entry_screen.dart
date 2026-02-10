import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/primary_button.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalEntryScreen({super.key, this.entry});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _journalController = TextEditingController();
  final JournalService _journalService = JournalService();
  String? _selectedMood;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _journalController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
    }
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Journal' : 'Edit Journal'),
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveJournal,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  MoodSelector(
                    selectedMood: _selectedMood,
                    onMoodSelected: (mood) {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _journalController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts here...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).hintColor.withValues(alpha: 0.5),
                          ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Enhance with AI ✨',
                    isOutlined: true,
                    onPressed: () {
                      // AI Enhance functionality stub
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI Enhancement coming soon!')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveJournal() async {
    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Generate a title (e.g., first few words)
      // Simple strategy: first 20 chars or up to newline
      String content = _journalController.text.trim();
      String title = content.split('\n').first;
      if (title.length > 30) {
        title = '${title.substring(0, 30)}...';
      }
      if (title.isEmpty) title = 'Untitled';

      if (widget.entry == null) {
        await _journalService.addJournal(
          userId: user.uid,
          title: title,
          content: content,
          mood: _selectedMood ?? '😐',
        );
      } else {
        await _journalService.updateJournal(
          JournalEntry(
            id: widget.entry!.id,
            userId: widget.entry!.userId,
            content: content,
            mood: _selectedMood ?? widget.entry!.mood,
            createdAt: widget.entry!.createdAt,
            title: title,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving journal: $e')),
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
}
