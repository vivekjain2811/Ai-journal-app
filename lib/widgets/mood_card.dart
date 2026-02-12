import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_mood.dart';
import '../services/mood_service.dart';

class MoodCard extends StatefulWidget {
  const MoodCard({super.key});

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard> {
  final MoodService _moodService = MoodService();
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _selectedMood;

  final List<Map<String, String>> _moods = [
    {'label': 'Happy', 'emoji': '😊', 'color': '0xFF4CAF50'},
    {'label': 'Excited', 'emoji': '🤩', 'color': '0xFFFFC107'},
    {'label': 'Calm', 'emoji': '😌', 'color': '0xFF2196F3'},
    {'label': 'Sad', 'emoji': '😔', 'color': '0xFF9E9E9E'},
    {'label': 'Anxious', 'emoji': '😰', 'color': '0xFF607D8B'},
  ];

  void _onMoodSelected(String label, String emoji) {
    setState(() {
      _selectedMood = label;
    });

    if (_user != null) {
      _moodService.saveMood(
        _user.uid,
        emoji,
        label,
        DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DailyMood?>(
        stream: _moodService.getDailyMood(_user.uid, DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _selectedMood = snapshot.data!.label;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _moods.map((mood) {
                    final isSelected = _selectedMood == mood['label'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: GestureDetector(
                        onTap: () =>
                            _onMoodSelected(mood['label']!, mood['emoji']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(int.parse(mood['color']!)).withOpacity(0.2)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Color(int.parse(mood['color']!))
                                  : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              if (!isSelected)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mood['emoji']!,
                                style: TextStyle(
                                  fontSize: isSelected ? 32 : 28,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mood['label']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Color(int.parse(mood['color']!)) : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        });
  }
}
