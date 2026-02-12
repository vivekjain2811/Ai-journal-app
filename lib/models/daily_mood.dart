import 'package:cloud_firestore/cloud_firestore.dart';

class DailyMood {
  final String id;
  final String userId;
  final DateTime date;
  final String mood; // Emoji
  final String label; // Happy, Calm, etc.
  final DateTime createdAt;

  DailyMood({
    required this.id,
    required this.userId,
    required this.date,
    required this.mood,
    required this.label,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'mood': mood,
      'label': label,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DailyMood.fromMap(Map<String, dynamic> map, String id) {
    return DailyMood(
      id: id,
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      mood: map['mood'] ?? '😐',
      label: map['label'] ?? 'Neutral',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory DailyMood.fromSnapshot(DocumentSnapshot doc) {
    return DailyMood.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
