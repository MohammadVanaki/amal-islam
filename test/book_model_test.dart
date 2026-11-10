import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/library/data/models/book_model.dart';

void main() {
  group('BookModel Tests with Dijlah API fields', () {
    test('creates BookModel from real Dijlah API JSON correctly', () {
      final json = {
        'id': 484,
        'title': 'اضاءات إسلامية في التربية الأسرية',
        'writer_name': 'أمل الموسوي',
        'photo_url': 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/37.jpg',
        'pdf_link': 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/010.pdf',
        'txt': 'Library/amal_islam/010/453.txt',
        'number_pages': 43,
        'category': {
          'id': 10,
          'title': 'قضايا اسلامية',
        },
      };

      final book = BookModel.fromJson(json);
      expect(book.id, '484');
      expect(book.title, 'اضاءات إسلامية في التربية الأسرية');
      expect(book.author, 'أمل الموسوي');
      expect(book.hasPdf, isTrue);
      expect(book.hasText, isTrue);
      expect(book.bookType, BookType.sqliteDatabase); // High priority on Text!
      expect(book.pdfUrl, 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/010.pdf');
      expect(book.txtUrl, 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/453.txt');
      expect(book.coverUrl, 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/37.jpg');
      expect(book.pageCount, 43);
      expect(book.category, 'قضايا اسلامية');
    });
  });
}
