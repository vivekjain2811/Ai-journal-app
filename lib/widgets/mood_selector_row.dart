import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MoodSelectorRow extends StatefulWidget {
  final Function(String) onMoodSelected;
  final String? selectedMood;

  const MoodSelectorRow({
    super.key,
    required this.onMoodSelected,
    this.selectedMood,
  });

  @override
  State<MoodSelectorRow> createState() => _MoodSelectorRowState();
}

class _MoodSelectorRowState extends State<MoodSelectorRow> {
  final List<Map<String, String>> _moods = [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Calm', 'emoji': '😌'},
    {'label': 'Sad', 'emoji': '😔'},
    {'label': 'Anxious', 'emoji': '😰'},
    {'label': 'Angry', 'emoji': '😠'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _moods.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final isSelected = widget.selectedMood == mood['emoji'];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onMoodSelected(mood['emoji']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
                    : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20 : 16,
                vertical: 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Text(
                      mood['emoji']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood['label']!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
