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
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final querySnapshot = await _journalCollection
        .where('userId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
