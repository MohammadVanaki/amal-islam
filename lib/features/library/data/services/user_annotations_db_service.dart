import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bookmark_model.dart';
import '../models/note_model.dart';

class UserAnnotationsDbService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, 'user_annotations.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id TEXT NOT NULL,
            page_number INTEGER NOT NULL,
            title TEXT,
            snippet TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id TEXT NOT NULL,
            page_number INTEGER NOT NULL,
            selected_text TEXT NOT NULL,
            note TEXT NOT NULL,
            color_hex TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE reading_progress (
            book_id TEXT PRIMARY KEY,
            last_page INTEGER NOT NULL,
            total_pages INTEGER NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // --- Bookmarks ---
  Future<int> addBookmark(BookmarkModel bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', bookmark.toMap());
  }

  Future<int> removeBookmark(int id) async {
    final db = await database;
    return await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> removeBookmarkByPage(String bookId, int pageNumber) async {
    final db = await database;
    return await db.delete(
      'bookmarks',
      where: 'book_id = ? AND page_number = ?',
      whereArgs: [bookId, pageNumber],
    );
  }

  Future<bool> isPageBookmarked(String bookId, int pageNumber) async {
    final db = await database;
    final res = await db.query(
      'bookmarks',
      where: 'book_id = ? AND page_number = ?',
      whereArgs: [bookId, pageNumber],
    );
    return res.isNotEmpty;
  }

  Future<List<BookmarkModel>> getBookmarks(String bookId) async {
    final db = await database;
    final res = await db.query(
      'bookmarks',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page_number ASC',
    );
    return res.map((m) => BookmarkModel.fromMap(m)).toList();
  }

  // --- Notes & Highlights ---
  Future<int> addNote(NoteModel note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> updateNote(NoteModel note) async {
    if (note.id == null) return 0;
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<NoteModel>> getNotes(String bookId) async {
    final db = await database;
    final res = await db.query(
      'notes',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page_number ASC',
    );
    return res.map((m) => NoteModel.fromMap(m)).toList();
  }

  Future<List<NoteModel>> getNotesForPage(String bookId, int pageNumber) async {
    final db = await database;
    final res = await db.query(
      'notes',
      where: 'book_id = ? AND page_number = ?',
      whereArgs: [bookId, pageNumber],
    );
    return res.map((m) => NoteModel.fromMap(m)).toList();
  }

  // --- Reading Progress ---
  Future<void> saveReadingProgress({
    required String bookId,
    required int lastPage,
    required int totalPages,
  }) async {
    final db = await database;
    await db.insert(
      'reading_progress',
      {
        'book_id': bookId,
        'last_page': lastPage,
        'total_pages': totalPages,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getReadingProgress(String bookId) async {
    final db = await database;
    final res = await db.query(
      'reading_progress',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllRecentProgress() async {
    final db = await database;
    return await db.query(
      'reading_progress',
      orderBy: 'updated_at DESC',
      limit: 10,
    );
  }
}

