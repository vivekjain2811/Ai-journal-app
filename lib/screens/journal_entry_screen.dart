import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/journal_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/gradient_scaffold.dart';

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

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  
  void _startListening() async {
    // If not already explicitly listening, set state
    if (!_isListening) {
      setState(() => _isListening = true);
    }

    // Initialize if not already initialized or just re-initialize to be safe
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (mounted) {
           // If system signals end of listening...
           if (val == 'done' || val == 'notListening') {
             // Check if we SHOULD be listening (User hasn't pressed stop)
             if (_isListening) {
                // Restart immediately
                _startSpeechSession();
             }
           }
        }
      },
      onError: (val) {
        debugPrint('onError: $val');
        // On error (timeout, no match), restart if we should be listening
        if (mounted && _isListening) {
           _startSpeechSession();
        }
      },
      debugLogging: true, // Enable logs for debugging if needed
    );

    if (available) {
      _startSpeechSession();
    } else {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _startSpeechSession() {
    // Verify we are still supposed to be listening before calling listen
    if (!_isListening) return;

    // Capture current text to append new speech to it
    String originalText = _journalController.text;
    if (originalText.isNotEmpty && !originalText.endsWith(' ')) {
      originalText += ' ';
    }
    
    _speech.listen(
      onResult: (val) {
        if (mounted) {
          setState(() {
            // Only update text if we have recognized words
            if (val.recognizedWords.isNotEmpty) {
               _journalController.text = "$originalText${val.recognizedWords}";
               
               // Move cursor to end
               _journalController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _journalController.text.length));
            }
          });
        }
      },
      listenFor: const Duration(seconds: 60), // Set a reasonable duration loop
      pauseFor: const Duration(seconds: 60), // Try to keep it open
      cancelOnError: false,
      partialResults: true,
    );
  }

  void _stopListening() {
    // First update state to prevent auto-restart logic
    setState(() => _isListening = false);
    // Then stop the engine
    _speech.stop();
  }

  void _clearText() {
    setState(() {
      _journalController.clear();
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    _speech.cancel(); // cancel listening on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Journal' : 'Edit Journal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts here...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).hintColor.withOpacity(0.5),
                          ),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                  ),
                  // Add extra padding at bottom so text isn't hidden by keyboard/bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // AI Enhance Button
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI Enhancement coming soon!')),
                );
              },
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Enhance with AI'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const Spacer(),
            
            // Clear Button
            if (_journalController.text.isNotEmpty && !_isListening) ...[
              IconButton(
                onPressed: _clearText,
                icon: const Icon(Icons.close),
                tooltip: 'Clear',
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Mic Button
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              mini: true,
              elevation: 0,
              backgroundColor: _isListening 
                  ? Colors.redAccent 
                  : Theme.of(context).primaryColor,
              child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
            ),
          ],
        ),
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
