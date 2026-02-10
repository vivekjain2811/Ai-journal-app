import 'package:flutter/material.dart';

class MoodSelector extends StatefulWidget {
  final Function(String) onMoodSelected;
  final String? selectedMood;

  const MoodSelector({
    super.key,
    required this.onMoodSelected,
    this.selectedMood,
  });

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
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
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _moods.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final isSelected = widget.selectedMood == mood['emoji'];
          return GestureDetector(
            onTap: () => widget.onMoodSelected(mood['emoji']!),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                    ],
                  ),
                  child: Text(
                    mood['emoji']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood['label']!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
