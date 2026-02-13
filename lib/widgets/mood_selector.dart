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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _moods.map((mood) {
          final isSelected = widget.selectedMood == mood['emoji'];
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onMoodSelected(mood['emoji']!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                          : Border.all(color: Colors.transparent, width: 2),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.4),
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
                  const SizedBox(height: 8),
                  Text(
                    mood['label']!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
