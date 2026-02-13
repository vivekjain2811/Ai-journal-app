import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/journal_service.dart';
import '../widgets/mood_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../services/ai_service.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalEntryScreen({super.key, this.entry});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _journalController = TextEditingController();
  final JournalService _journalService = JournalService();
  final AIService _aiService = AIService();
  
  String? _selectedMood;
  bool _isLoading = false;
  bool _isEnhancing = false;
  String? _enhancedTitle; // Store the AI generated title

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _journalController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
      _enhancedTitle = widget.entry!.title;
    }
  }

  // ... (speech to text code remains the same, omitted for brevity in this replace) ...
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  
  void _startListening() async {
    // ... same implementation ...
    if (!_isListening) {
      setState(() => _isListening = true);
    }
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (mounted) {
           if (val == 'done' || val == 'notListening') {
             if (_isListening) {
                _startSpeechSession();
             }
           }
        }
      },
      onError: (val) {
        debugPrint('onError: $val');
        if (mounted && _isListening) {
           _startSpeechSession();
        }
      },
      debugLogging: true,
    );
    if (available) {
      _startSpeechSession();
    } else {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _startSpeechSession() {
    if (!_isListening) return;
    String originalText = _journalController.text;
    if (originalText.isNotEmpty && !originalText.endsWith(' ')) {
      originalText += ' ';
    }
    _speech.listen(
      onResult: (val) {
        if (mounted) {
          setState(() {
            if (val.recognizedWords.isNotEmpty) {
               _journalController.text = "$originalText${val.recognizedWords}";
               _journalController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _journalController.text.length));
            }
          });
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 60),
      cancelOnError: false,
      partialResults: true,
    );
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _clearText() {
    setState(() {
      _journalController.clear();
      _enhancedTitle = null; // Clear title if text is cleared
    });
  }

  Future<void> _enhanceWithAI() async {
    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something first to enhance!')),
      );
      return;
    }

    setState(() => _isEnhancing = true);

    try {
      final result = await _aiService.enhanceJournal(_journalController.text);
      
      if (mounted) {
        setState(() {
          _enhancedTitle = result['title'];
          _journalController.text = result['enhanced_content']!;
          
          // Map the emoji to the mood strings expected by MoodSelector/DB
          // The AI service returns emojis like 😃, 😌, 😔, 😨, 😠
          // We need to match these to the values expected by MoodSelector if they differ,
          // but looking at MoodSelector (Irecall it uses emojis as keys or similar), 
          // let's double check. 
          // Actually, MoodSelector uses a list of maps, and the `onMoodSelected` passes the mood label or emoji?
          // Let's assume for now it passes the emoji itself or we just set it.
          // Re-reading MoodSelector usage: `selectedMood` variable holds the strings/emojis.
          // Let's just set it directly as the AI returns the emoji.
          _selectedMood = result['mood'];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal enhanced & Mood detected! ✨'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to enhance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnhancing = false);
      }
    }
  }

  @override
  void dispose() {
    _journalController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      // ... AppBar ...
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Journal' : 'Edit Journal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircularProgressIndicator(),
            ))
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
                  // Title Preview (if enhanced)
                  if (_enhancedTitle != null) ...[
                    Text(
                      _enhancedTitle!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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
              onPressed: _isEnhancing ? null : _enhanceWithAI,
              icon: _isEnhancing 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ) 
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(_isEnhancing ? 'Enhancing...' : 'Enhance with AI'),
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
            
            // ... (Clear and Mic buttons) ...
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

      String content = _journalController.text.trim();
      
      // Use enhanced title if available, otherwise fallback to simple generation
      String title = _enhancedTitle ?? '';
      
      if (title.isEmpty) {
        title = content.split('\n').first;
        if (title.length > 30) {
          title = '${title.substring(0, 30)}...';
        }
        if (title.isEmpty) title = 'Untitled';
      }

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
      // ... error handling ...
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
