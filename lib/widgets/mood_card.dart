import 'package:flutter/material.dart';

class MoodCard extends StatelessWidget {
  const MoodCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Daily Mood',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'How are you feeling today?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                _MoodIcon(label: 'Happy', emoji: '😊'),
                _MoodIcon(label: 'Calm', emoji: '😌'),
                _MoodIcon(label: 'Sad', emoji: '😔'),
                _MoodIcon(label: 'Anxious', emoji: '😰'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodIcon extends StatelessWidget {
  final String label;
  final String emoji;

  const _MoodIcon({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
