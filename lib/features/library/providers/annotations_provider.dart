import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bookmark_model.dart';
import '../data/models/note_model.dart';
import '../data/services/user_annotations_db_service.dart';

final annotationsDbServiceProvider = Provider<UserAnnotationsDbService>((ref) {
  return UserAnnotationsDbService();
});

class BookmarksNotifier extends StateNotifier<List<BookmarkModel>> {
  final UserAnnotationsDbService _service;
  final String bookId;

  BookmarksNotifier(this._service, this.bookId) : super([]) {
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    final list = await _service.getBookmarks(bookId);
    state = list;
  }

  Future<bool> toggleBookmark({
    required int pageNumber,
    String? title,
    String? snippet,
  }) async {
    final isBookmarked = await _service.isPageBookmarked(bookId, pageNumber);
    if (isBookmarked) {
      await _service.removeBookmarkByPage(bookId, pageNumber);
    } else {
      await _service.addBookmark(
        BookmarkModel(
          bookId: bookId,
          pageNumber: pageNumber,
          title: title,
          snippet: snippet,
          createdAt: DateTime.now(),
        ),
      );
    }
    await loadBookmarks();
    return !isBookmarked;
  }

  Future<void> removeBookmark(int id) async {
    await _service.removeBookmark(id);
    await loadBookmarks();
  }
}

final bookmarksProvider =
    StateNotifierProvider.family<BookmarksNotifier, List<BookmarkModel>, String>((ref, bookId) {
  final service = ref.watch(annotationsDbServiceProvider);
  return BookmarksNotifier(service, bookId);
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  final UserAnnotationsDbService _service;
  final String bookId;

  NotesNotifier(this._service, this.bookId) : super([]) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    final list = await _service.getNotes(bookId);
    state = list;
  }

  Future<void> addNote({
    required int pageNumber,
    required String selectedText,
    required String note,
    required String colorHex,
  }) async {
    await _service.addNote(
      NoteModel(
        bookId: bookId,
        pageNumber: pageNumber,
        selectedText: selectedText,
        note: note,
        colorHex: colorHex,
        createdAt: DateTime.now(),
      ),
    );
    await loadNotes();
  }

  Future<void> deleteNote(int id) async {
    await _service.deleteNote(id);
    await loadNotes();
  }

  Future<void> updateNote(NoteModel note) async {
    await _service.updateNote(note);
    await loadNotes();
  }
}

final notesProvider =
    StateNotifierProvider.family<NotesNotifier, List<NoteModel>, String>((ref, bookId) {
  final service = ref.watch(annotationsDbServiceProvider);
  return NotesNotifier(service, bookId);
});

final recentReadingHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(annotationsDbServiceProvider);
  return await service.getAllRecentProgress();
});

