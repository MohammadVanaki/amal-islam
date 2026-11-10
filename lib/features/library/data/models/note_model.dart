class NoteModel {
  final int? id;
  final String bookId;
  final int pageNumber;
  final String selectedText;
  final String note;
  final String colorHex;
  final DateTime createdAt;

  const NoteModel({
    this.id,
    required this.bookId,
    required this.pageNumber,
    required this.selectedText,
    required this.note,
    required this.colorHex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'page_number': pageNumber,
      'selected_text': selectedText,
      'note': note,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int?,
      bookId: (map['book_id'] ?? '').toString(),
      pageNumber: map['page_number'] as int? ?? 1,
      selectedText: map['selected_text'] as String? ?? '',
      note: map['note'] as String? ?? '',
      colorHex: map['color_hex'] as String? ?? '0x66FFEB3B',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

