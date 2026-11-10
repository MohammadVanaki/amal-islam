import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  /// Get User Profile Document
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  /// Sync Bookmark to Cloud
  Future<void> syncBookmark({
    required String uid,
    required String bookmarkId,
    required String bookId,
    required int pageNumber,
    String? title,
  }) async {
    await _usersRef.doc(uid).collection('bookmarks').doc(bookmarkId).set({
      'bookId': bookId,
      'pageNumber': pageNumber,
      'title': title ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete Bookmark from Cloud
  Future<void> deleteBookmark(String uid, String bookmarkId) async {
    await _usersRef.doc(uid).collection('bookmarks').doc(bookmarkId).delete();
  }

  /// Sync Note to Cloud
  Future<void> syncNote({
    required String uid,
    required String noteId,
    required String bookId,
    required int pageNumber,
    required String noteText,
    String? selectedText,
    String? color,
  }) async {
    await _usersRef.doc(uid).collection('notes').doc(noteId).set({
      'bookId': bookId,
      'pageNumber': pageNumber,
      'noteText': noteText,
      'selectedText': selectedText ?? '',
      'color': color ?? '#FFD54F',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete Note from Cloud
  Future<void> deleteNote(String uid, String noteId) async {
    await _usersRef.doc(uid).collection('notes').doc(noteId).delete();
  }

  /// Sync Reading Progress to Cloud
  Future<void> syncReadingProgress({
    required String uid,
    required String bookId,
    required int lastPage,
    required int totalPages,
  }) async {
    await _usersRef.doc(uid).collection('reading_progress').doc(bookId).set({
      'lastPage': lastPage,
      'totalPages': totalPages,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream User Bookmarks
  Stream<List<Map<String, dynamic>>> streamBookmarks(String uid) {
    return _usersRef
        .doc(uid)
        .collection('bookmarks')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Stream User Notes
  Stream<List<Map<String, dynamic>>> streamNotes(String uid) {
    return _usersRef
        .doc(uid)
        .collection('notes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}

