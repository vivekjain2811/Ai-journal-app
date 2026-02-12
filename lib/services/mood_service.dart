import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_mood.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'daily_moods';

  // Helper to normalize date to start of day (UTC or Local depending on app logic, sticking to UTC for consistency if possible, but Firestore Timestamps are UTC.
  // For simplicity, we'll store specific dates at midnight local or UTC. 
  // Let's use a string-based ID for the document to easily enforce "one mood per day" -> `userId_YYYY-MM-DD`
  String _getDateId(String userId, DateTime date) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return "${userId}_$dateStr";
  }

  Future<void> saveMood(String userId, String mood, String label, DateTime date) async {
    final docId = _getDateId(userId, date);
    final moodEntry = DailyMood(
      id: docId,
      userId: userId,
      date: DateTime(date.year, date.month, date.day), // Normalize to midnight
      mood: mood,
      label: label,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).doc(docId).set(moodEntry.toMap());
  }

  Stream<DailyMood?> getDailyMood(String userId, DateTime date) {
    final docId = _getDateId(userId, date);
    return _firestore.collection(_collection).doc(docId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return DailyMood.fromSnapshot(doc);
      }
      return null;
    });
  }

  Stream<List<DailyMood>> getMoodsForMonth(String userId, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DailyMood.fromSnapshot(doc)).toList();
    });
  }
}
