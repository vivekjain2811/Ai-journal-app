import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JournalListTile extends StatelessWidget {
  final String title;
  final String preview;
  final DateTime date;
  final String moodEmoji;

  const JournalListTile({
    super.key,
    required this.title,
    required this.preview,
    required this.date,
    required this.moodEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            shape: BoxShape.circle,
          ),
          child: Text(moodEmoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat.MMMEd().format(date),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
