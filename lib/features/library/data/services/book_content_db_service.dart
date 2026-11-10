import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';

class BookChapter {
  final int id;
  final int pageNumber;
  final String title;

  const BookChapter({
    required this.id,
    required this.pageNumber,
    required this.title,
  });
}

class BookPageContent {
  final int pageNumber;
  final String html;
  final String text;
  final String? title;

  const BookPageContent({
    required this.pageNumber,
    required this.html,
    required this.text,
    this.title,
  });
}

class BookSearchResult {
  final int pageNumber;
  final String snippet;

  const BookSearchResult({
    required this.pageNumber,
    required this.snippet,
  });
}

class BookContentDbService {
  final String dbPath;
  Database? _db;
  String? _tableName;
  String? _pageCol;
  String? _textCol;
  String? _titleCol;
  int _totalPages = 0;

  List<BookChapter> _chapters = [];
  Map<int, String> _chapterTitlesByPage = {};

  BookContentDbService(this.dbPath);

  List<BookChapter> get chapters => _chapters;

  Future<void> initialize() async {
    _db = await openDatabase(dbPath, readOnly: true);

    // Discover table and columns
    final tables = await _db!.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );

    if (tables.isEmpty) {
      throw Exception('لا توجد جداول بيانات في هذا الكتاب');
    }

    final tableNames = tables.map((t) => t['name'] as String).toList();

    // 1. Pages table: find table containing '_pages' or ending with 'pages' or 'page'
    String? chosenPagesTable;
    for (final name in tableNames) {
      final lower = name.toLowerCase();
      if (lower.contains('_pages') || lower.endsWith('pages') || lower == 'pages') {
        chosenPagesTable = name;
        break;
      }
    }

    if (chosenPagesTable == null) {
      for (final name in tableNames) {
        final lower = name.toLowerCase();
        if (lower != 'books' &&
            !lower.contains('chapter') &&
            (lower.contains('page') || lower.contains('content') || lower.contains('nass') || lower.contains('text'))) {
          chosenPagesTable = name;
          break;
        }
      }
    }

    if (chosenPagesTable == null) {
      int maxCount = -1;
      for (final name in tableNames) {
        if (name.toLowerCase() == 'books' || name.toLowerCase().contains('chapter')) continue;
        try {
          final countRes = await _db!.rawQuery('SELECT COUNT(*) as count FROM $name');
          final c = Sqflite.firstIntValue(countRes) ?? 0;
          if (c > maxCount) {
            maxCount = c;
            chosenPagesTable = name;
          }
        } catch (_) {}
      }
    }

    _tableName = chosenPagesTable ?? tableNames.first;

    final columnsInfo = await _db!.rawQuery('PRAGMA table_info($_tableName)');
    final colNames = columnsInfo.map((c) => (c['name'] as String)).toList();

    // Find text column
    for (final col in colNames) {
      final l = col.toLowerCase();
      if (l == '_text' || l == 'text' || l == 'nass' || l.contains('content') || l.contains('body') || l.contains('page_text') || l.contains('text')) {
        _textCol = col;
        break;
      }
    }
    _textCol ??= colNames.firstWhere((c) => c.toLowerCase() != 'id' && c.toLowerCase() != 'page', orElse: () => colNames.first);

    // Find page number column
    for (final col in colNames) {
      final l = col.toLowerCase();
      if (l == 'page' || l == 'page_number' || l == 'page_no' || l == 'pagenum') {
        _pageCol = col;
        break;
      }
    }
    _pageCol ??= colNames.contains('id') ? 'id' : colNames.first;

    // Find title column in pages table
    for (final col in colNames) {
      final l = col.toLowerCase();
      if (l.contains('title') || l.contains('heading') || l.contains('bab') || l.contains('fasl')) {
        _titleCol = col;
        break;
      }
    }

    final countResult = await _db!.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    _totalPages = Sqflite.firstIntValue(countResult) ?? 0;

    // Discover chapters / table of contents
    _chapters = [];
    _chapterTitlesByPage = {};
    String? chapterTable;
    for (final name in tableNames) {
      final lower = name.toLowerCase();
      if (lower.contains('chapter') || lower.contains('fihris') || lower.contains('toc')) {
        chapterTable = name;
        break;
      }
    }

    if (chapterTable != null) {
      try {
        final chColsInfo = await _db!.rawQuery('PRAGMA table_info($chapterTable)');
        final chCols = chColsInfo.map((c) => (c['name'] as String).toLowerCase()).toList();

        final pageCol = chCols.contains('page') ? 'page' : chCols.firstWhere((c) => c.contains('page'), orElse: () => 'id');
        final titleCol = chCols.contains('title') ? 'title' : chCols.firstWhere((c) => c.contains('title') || c.contains('name'), orElse: () => 'title');

        final chRows = await _db!.query(chapterTable, orderBy: 'CAST($pageCol AS INTEGER) ASC');
        for (final r in chRows) {
          final p = int.tryParse(r[pageCol]?.toString() ?? '') ?? 1;
          final t = _cleanHtml((r[titleCol] ?? '').toString()).trim();
          if (t.isNotEmpty) {
            final ch = BookChapter(
              id: (r['id'] as int?) ?? p,
              pageNumber: p,
              title: t,
            );
            _chapters.add(ch);
            _chapterTitlesByPage[p] = t;
          }
        }
      } catch (e) {
        developer.log('Optional chapters table could not be read: $e', name: 'BookContentDbService');
      }
    }
  }

  int get totalPages => _totalPages > 0 ? _totalPages : 1;

  Future<BookPageContent?> getPage(int pageNumber) async {
    if (_db == null) await initialize();

    final pageStr = pageNumber.toString();
    final results = await _db!.query(
      _tableName!,
      where: '$_pageCol = ? OR $_pageCol = ?',
      whereArgs: [pageNumber, pageStr],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return _parsePageRow(pageNumber, results.first);
    }

    // Fallback: try offset if page numbers are not 1-to-1 with pageCol
    final offsetResults = await _db!.query(
      _tableName!,
      limit: 1,
      offset: (pageNumber - 1).clamp(0, totalPages - 1),
    );

    if (offsetResults.isNotEmpty) {
      return _parsePageRow(pageNumber, offsetResults.first);
    }

    return null;
  }

  Future<Map<int, BookPageContent>> getPagesRange(
    int startPage,
    int endPage,
  ) async {
    if (_db == null) await initialize();
    if (_tableName == null) return {};

    final Map<int, BookPageContent> map = {};
    final clampedStart = startPage.clamp(1, totalPages);
    final clampedEnd = endPage.clamp(clampedStart, totalPages);

    try {
      final results = await _db!.query(
        _tableName!,
        where:
            'CAST($_pageCol AS INTEGER) >= ? AND CAST($_pageCol AS INTEGER) <= ?',
        whereArgs: [clampedStart, clampedEnd],
        orderBy: 'CAST($_pageCol AS INTEGER) ASC',
      );

      if (results.isNotEmpty) {
        for (final row in results) {
          final p =
              int.tryParse(row[_pageCol!]?.toString() ?? '') ?? clampedStart;
          if (p >= clampedStart && p <= clampedEnd) {
            map[p] = _parsePageRow(p, row);
          }
        }
      }

      // Fallback if pageCol is not sequentially numbered
      if (map.length < (clampedEnd - clampedStart + 1)) {
        final offset = (clampedStart - 1).clamp(0, totalPages - 1);
        final limit = clampedEnd - clampedStart + 1;
        final offsetResults = await _db!.query(
          _tableName!,
          offset: offset,
          limit: limit,
        );
        for (int i = 0; i < offsetResults.length; i++) {
          final p = clampedStart + i;
          if (!map.containsKey(p)) {
            map[p] = _parsePageRow(p, offsetResults[i]);
          }
        }
      }
    } catch (e) {
      developer.log('Error in getPagesRange: $e', name: 'BookContentDbService');
    }

    return map;
  }

  BookPageContent _parsePageRow(int pageNumber, Map<String, dynamic> row) {
    final rawText = (row[_textCol!] ?? '').toString();
    String? title;

    if (_titleCol != null && row[_titleCol!] != null) {
      final t = row[_titleCol!].toString().trim();
      if (t.isNotEmpty) title = _cleanHtml(t);
    }

    if (title == null || title.isEmpty) {
      title = _chapterTitlesByPage[pageNumber];
    }

    // Check if raw text starts with or contains <h1...>Heading</h1>
    final headingMatch = RegExp(r'<h[1-3][^>]*>(.*?)</h[1-3]>', dotAll: true, caseSensitive: false).firstMatch(rawText);
    if (headingMatch != null) {
      final hText = _cleanHtml(headingMatch.group(1) ?? '').trim();
      if (hText.isNotEmpty) {
        title ??= hText;
      }
    }

    final cleanText = _cleanHtml(rawText);
    final displayHtml = _prepareHtmlForDisplay(rawText, title, pageNumber);

    return BookPageContent(
      pageNumber: pageNumber,
      html: displayHtml,
      text: cleanText.isNotEmpty ? cleanText : 'صفحة فارغة',
      title: title,
    );
  }

  static String _prepareHtmlForDisplay(String raw, String? chapterTitle, int pageNumber) {
    if (raw.trim().isEmpty) {
      return '<div class="centertxt"><p>صفحة فارغة</p></div>';
    }

    var html = raw.trim();

    // If text does not contain HTML tags, convert plain text into HTML paragraphs
    final hasHtmlTags = RegExp(r'<[a-z/][\s\S]*?>', caseSensitive: false).hasMatch(html);
    if (!hasHtmlTags) {
      final paragraphs = html.split('\n\n');
      html = paragraphs
          .map((p) => '<p>${p.replaceAll('\n', '<br>')}</p>')
          .join('\n');
    }

    // If page is the beginning of a chapter and does not already contain a heading tag, prepend heading
    final hasHeading = RegExp(r'<h[1-3][^>]*>', caseSensitive: false).hasMatch(html);
    if (!hasHeading && chapterTitle != null && chapterTitle.trim().isNotEmpty) {
      html = '<h1 class="tit1">${chapterTitle.trim()}</h1>\n$html';
    }

    return html;
  }

  static String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?(p|div|section|article|blockquote)[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'")
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<List<BookSearchResult>> search(String query) async {
    if (_db == null) await initialize();
    if (query.trim().isEmpty) return [];

    final results = await _db!.query(
      _tableName!,
      columns: [_pageCol!, _textCol!],
      where: '$_textCol LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
    );

    final list = <BookSearchResult>[];
    for (final r in results) {
      final rawPage = r[_pageCol!];
      final pageNum = int.tryParse(rawPage?.toString() ?? '') ?? 1;
      final fullText = _cleanHtml((r[_textCol!] ?? '').toString());
      final idx = fullText.indexOf(query);
      if (idx == -1) continue;
      final start = (idx - 30).clamp(0, fullText.length);
      final end = (idx + query.length + 50).clamp(0, fullText.length);
      final snippet = fullText.substring(start, end).replaceAll('\n', ' ');

      list.add(BookSearchResult(pageNumber: pageNum, snippet: '...$snippet...'));
    }

    return list;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
