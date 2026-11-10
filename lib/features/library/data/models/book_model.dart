enum BookType {
  sqliteDatabase, // Text version (High Priority)
  pdf,            // PDF version
}

class BookModel {
  final String id;
  final String title;
  final String author;
  final String? category;
  final String? description;
  final String? coverUrl;
  final String? pdfUrl;
  final String? txtUrl;
  final String? zipUrl;
  final int pageCount;
  final String? fileSize;
  final double rating;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.category,
    this.description,
    this.coverUrl,
    this.pdfUrl,
    this.txtUrl,
    this.zipUrl,
    this.pageCount = 0,
    this.fileSize,
    this.rating = 4.9,
  });

  bool get hasPdf => pdfUrl != null && pdfUrl!.trim().isNotEmpty;
  bool get hasText => true; // All books in the library have textual database available via the API
  BookType get bookType => BookType.sqliteDatabase; // Default priority is always Text!

  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? category,
    String? description,
    String? coverUrl,
    String? pdfUrl,
    String? txtUrl,
    String? zipUrl,
    int? pageCount,
    String? fileSize,
    double? rating,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      txtUrl: txtUrl ?? this.txtUrl,
      zipUrl: zipUrl ?? this.zipUrl,
      pageCount: pageCount ?? this.pageCount,
      fileSize: fileSize ?? this.fileSize,
      rating: rating ?? this.rating,
    );
  }

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final idVal = (json['id'] ?? json['id_show'] ?? json['_id'] ?? '').toString();

    // PDF link
    final pdf = json['pdf_link'] ?? json['pdfUrl'] ?? json['pdf_url'] ?? json['pdf'];

    // TXT link
    final txt = json['txt'] ?? json['txt_url'] ?? json['text_url'];
    String? txtLink;
    if (txt != null && txt.toString().isNotEmpty) {
      final t = txt.toString();
      txtLink = t.startsWith('http') ? t : 'https://library.dijlah.org/upload_list/source/$t';
    }

    final zip = json['zipUrl'] ?? json['zip_url'] ?? json['download_url'] ?? json['url'];

    // Cover image
    final cover = json['photo_url'] ?? json['coverUrl'] ?? json['cover_url'] ?? json['image'] ?? json['thumbnail'];

    // Author
    final writer = json['writer_name'] ?? json['author'] ?? json['scholar_name'] ?? json['writer'] ?? 'أمل الموسوي';

    // Category
    String? categoryName;
    if (json['category'] is Map) {
      categoryName = json['category']['title']?.toString();
    } else if (json['category'] != null) {
      categoryName = json['category'].toString();
    } else {
      categoryName = json['category_name']?.toString() ?? 'قضايا إسلامية';
    }

    // Page count
    final pages = json['number_pages'] ?? json['pageCount'] ?? json['pages_count'] ?? json['pages'] ?? 0;

    return BookModel(
      id: idVal,
      title: json['title'] ?? json['name'] ?? 'بدون عنوان',
      author: writer.toString().isNotEmpty ? writer.toString() : 'أمل الموسوي',
      category: categoryName,
      description: json['description'] ?? json['summary'],
      coverUrl: (cover != null && cover.toString().isNotEmpty) ? cover.toString() : null,
      pdfUrl: (pdf != null && pdf.toString().isNotEmpty) ? pdf.toString() : null,
      txtUrl: txtLink,
      zipUrl: (zip != null && zip.toString().isNotEmpty) ? zip.toString() : null,
      pageCount: pages is int ? pages : (int.tryParse(pages.toString()) ?? 0),
      fileSize: json['fileSize'] ?? json['file_size'] ?? json['size'],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.9,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'coverUrl': coverUrl,
      'pdfUrl': pdfUrl,
      'txtUrl': txtUrl,
      'zipUrl': zipUrl,
      'pageCount': pageCount,
      'fileSize': fileSize,
      'rating': rating,
    };
  }
}
