class BookmarkModel {
  final int? id;
  final String bookId;
  final int pageNumber;
  final String? title;
  final String? snippet;
  final DateTime createdAt;

  const BookmarkModel({
    this.id,
    required this.bookId,
    required this.pageNumber,
    this.title,
    this.snippet,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'page_number': pageNumber,
      'title': title,
      'snippet': snippet,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as int?,
      bookId: (map['book_id'] ?? '').toString(),
      pageNumber: map['page_number'] as int? ?? 1,
      title: map['title'] as String?,
      snippet: map['snippet'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

