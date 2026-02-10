import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String userId;
  final String content;
  final String mood;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String title;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.content,
    required this.mood,
    required this.createdAt,
    this.updatedAt,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'mood': mood,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'title': title,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map, String id) {
    return JournalEntry(
      id: id,
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      mood: map['mood'] ?? '😐',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      title: map['title'] ?? '',
    );
  }

  factory JournalEntry.fromSnapshot(DocumentSnapshot doc) {
    return JournalEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
