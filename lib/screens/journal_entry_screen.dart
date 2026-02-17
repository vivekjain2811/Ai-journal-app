import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/ai_service.dart'; // Restore this import
import '../services/notification_service.dart';



import '../widgets/mood_selector_row.dart';
import '../widgets/ai_suggestion_sheet.dart';
import '../widgets/gradient_scaffold.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalEntryScreen({super.key, this.entry});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _journalController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(); 
  final JournalService _journalService = JournalService();
  final AIService _aiService = AIService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String? _selectedMood;
  bool _isLoading = false;
  bool _isEnhancing = false;
  bool _isListening = false;
  // Removed _enhancedTitle variable as we now use _titleController
  Timer? _autoSaveTimer;
  int _wordCount = 0;
  String _lastSavedStatus = 'Draft';
  String _textBeforeListening = ''; // Store text before listening starts

  // Animation controller for mic pulse
  late AnimationController _micController;
  late Animation<double> _micAnimation;

  @override
  void initState() {
    super.initState();
    _micController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_micController);

    if (widget.entry != null) {
      _journalController.text = widget.entry!.content;
      _titleController.text = widget.entry!.title; // Initialize title
      _selectedMood = widget.entry!.mood;
      _updateWordCount();
      _lastSavedStatus = 'Saved';
    } else {
      _journalController.addListener(_onTextChanged);
      _titleController.addListener(_onTextChanged); // Listen to title changes too
    }
  }

  @override
  void dispose() {
    _journalController.dispose();
    _titleController.dispose();
    _micController.dispose();
    _autoSaveTimer?.cancel();
    _speech.stop();
    super.dispose();
  }

  void _onTextChanged() {
    _updateWordCount();
    // Debounce auto-save or just update status
    _lastSavedStatus = 'Typing...';
    setState(() {});
    
    // Simple auto-save simulation for UI feedback
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _lastSavedStatus = 'Saved');
      }
    });
  }

  void _updateWordCount() {
    final text = _journalController.text.trim();
    setState(() {
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  // ... (Speech to Text Logic - streamlined) ...
  void _toggleListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    } else {
      bool available = await _speech.initialize(
        onError: (val) => setState(() => _isListening = false),
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             if (mounted) setState(() => _isListening = false);
          }
        },
      );
      if (available) {
        _textBeforeListening = _journalController.text; // Capture current text
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
             setState(() {
                if (val.recognizedWords.isNotEmpty) {
                  // Append recognized words to the ORIGINAL text
                   final newText = "$_textBeforeListening ${val.recognizedWords}"; 
                   _journalController.text = newText;
                   _journalController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _journalController.text.length));
                   _onTextChanged();
                }
             });
          },
        );
      }
    }
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
        // Show Bottom Sheet for review
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AISuggestionSheet(
            originalText: _journalController.text,
            enhancedText: result['enhanced_content']!,
            newTitle: result['title'],
            detectedMood: result['mood'], 
            onAccept: () {
              Navigator.pop(context);
              setState(() {
                _titleController.text = result['title'] ?? _titleController.text; 
                _journalController.text = result['enhanced_content']!;
                _selectedMood = result['mood']; // Always overwrite mood with AI detected one
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enhancements applied! ✨')),
              );
            },
            onKeepOriginal: () {
              Navigator.pop(context);
            },
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

  Future<void> _saveJournal() async {
    if (_journalController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final content = _journalController.text.trim();
      // Use title from controller, or fallback to first line
      String title = _titleController.text.trim();
      if (title.isEmpty) {
         title = content.split('\n').firstOfNotNull() ?? 'Untitled';
      }
      
      String finalTitle = title.length > 50 ? '${title.substring(0, 50)}...' : title;

      if (widget.entry == null) {
        await _journalService.addJournal(
          userId: user.uid,
          title: finalTitle,
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
            title: finalTitle,
          ),
        );
      }
      
      // Cancel reminders as the user has journaled
      await NotificationService().completeForToday();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              widget.entry == null ? 'New Journal' : 'Edit Journal',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            Text(
              _getFormattedDate(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _saveJournal,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          )
        ],
      ),
      body: Column(
        children: [
          // Prompt & Mood Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Prompt (Static for now, could be dynamic)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, 
                           color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "What made you smile today?",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                MoodSelectorRow(
                  selectedMood: _selectedMood,
                  onMoodSelected: (mood) => setState(() => _selectedMood = mood),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity, 
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header Stats (Word Count & Saved Status) - Moved to top
                   Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$_wordCount words',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                             color: Colors.grey.withValues(alpha: 0.4),
                             shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _lastSavedStatus,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _lastSavedStatus == 'Saved' 
                                ? Colors.green 
                                : Colors.grey.withValues(alpha: 0.7),
                             fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                   // Title Field (Editable)
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                       hintText: 'Title (optional)',
                       hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                       ),
                       border: InputBorder.none,
                       contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Content Field
                  Expanded(
                    child: TextField(
                      controller: _journalController,
                      maxLines: null, 
                      expands: true, 
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.withValues(alpha: 0.5),
                              fontSize: 18,
                            ),
                          contentPadding: EdgeInsets.zero,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 18,
                            height: 1.6,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Floating Action Buttons (Enhance + Mic)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Enhance Button
             FloatingActionButton.extended(
                heroTag: 'enhance',
                onPressed: _isEnhancing ? null : _enhanceWithAI,
                backgroundColor: Theme.of(context).primaryColor,
                icon: _isEnhancing
                    ? const SizedBox(
                        width: 16, height: 16, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isEnhancing ? 'Enhancing...' : 'Enhance',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
             const SizedBox(width: 16),
             
             // Mic Button
             GestureDetector(
               onTap: _toggleListening,
               child: AnimatedBuilder(
                 animation: _micAnimation,
                 builder: (context, child) {
                   return Transform.scale(
                     scale: _isListening ? _micAnimation.value : 1.0,
                     child: child,
                   );
                 },
                 child: Container(
                   height: 56, 
                   width: 56,
                   decoration: BoxDecoration(
                     color: _isListening ? Colors.redAccent : Theme.of(context).cardColor,
                     shape: BoxShape.circle,
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.1),
                         blurRadius: 8,
                         offset: const Offset(0, 4),
                       )
                     ],
                     border: Border.all(
                       color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                     ),
                   ),
                   child: Icon(
                     _isListening ? Icons.stop : Icons.mic,
                     color: _isListening ? Colors.white : Theme.of(context).primaryColor,
                   ),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}'; 
  }
}

extension ListGetExtension on List<String> {
   String? firstOfNotNull() {
      if (isEmpty) return null;
      return first;
   }
}
