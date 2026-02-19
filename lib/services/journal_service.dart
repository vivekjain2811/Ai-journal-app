import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/journal_entry.dart';

class JournalService {
  final CollectionReference _journalCollection =
      FirebaseFirestore.instance.collection('journals');

  Future<void> createJournal(JournalEntry entry) async {
    // We let Firestore generate the ID if not provided, or use the one in entry.
    // However, usually we want Firestore to generate.
    // Let's assume entry.id is empty for new entries and we want a new doc.
    if (entry.id.isEmpty) {
        await _journalCollection.add(entry.toMap());
    } else {
        await _journalCollection.doc(entry.id).set(entry.toMap());
    }
  }

  Future<void> addJournal({
    required String userId,
    required String title,
    required String content,
    required String mood,
  }) async {
    await _journalCollection.add({
      'userId': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<JournalEntry>> getJournals(String userId) {
    return _journalCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Handle server timestamp which might be null initially
        if (data['createdAt'] == null) {
            data['createdAt'] = Timestamp.now();
        }
        return JournalEntry.fromMap(data, doc.id);
      }).toList();
    });
  }

  Future<void> updateJournal(JournalEntry entry) async {
    await _journalCollection.doc(entry.id).update({
      'title': entry.title,
      'content': entry.content,
      'mood': entry.mood,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJournal(String id) async {
    await _journalCollection.doc(id).delete();
  }

  Future<bool> hasJournaledToday(String userId) async {
    final now = DateTime.now();

    // Use the same index as getJournals (userId + createdAt desc) — no extra index needed
    final querySnapshot = await _journalCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return false;

    final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;
    if (createdAt == null) return false;

    final entryDate = createdAt.toDate();
    return entryDate.year == now.year &&
        entryDate.month == now.month &&
        entryDate.day == now.day;
  }
  Stream<Map<String, dynamic>> getJournalStats(String userId) {
    return getJournals(userId).map((entries) {
      if (entries.isEmpty) {
        return {'totalEntries': 0, 'currentStreak': 0};
      }

      // 1. Total Entries
      int totalEntries = entries.length;

      // 2. Current Streak
      // Extract unique dates (ignoring time)
      final uniqueDates = entries.map((e) {
        final date = e.createdAt;
        return DateTime(date.year, date.month, date.day);
      }).toSet().toList();

      // Sort descending (newest first)
      uniqueDates.sort((a, b) => b.compareTo(a));

      if (uniqueDates.isEmpty) return {'totalEntries': totalEntries, 'currentStreak': 0};

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));

      // Check if the most recent entry is today or yesterday
      // If the last entry was before yesterday, the streak is broken (0).
      if (uniqueDates.first.isBefore(yesterdayDate)) {
         return {'totalEntries': totalEntries, 'currentStreak': 0};
      }
      
      int streak = 0;
      // We start checking from the most recent entry.
      // Ideally, it should be Today or Yesterday.
      DateTime checkDate = uniqueDates.first;
      
      // If the most recent entry is Today, we start counting from Today.
      // If it is Yesterday, we start from Yesterday.
      // We verified above that it IS either Today or Yesterday.

      for (final date in uniqueDates) {
        if (date.isAtSameMomentAs(checkDate)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          // Gap found, streak ends
          break;
        }
      }

      return {
        'totalEntries': totalEntries,
        'currentStreak': streak,
      };
    });
  }
}
