import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/library/data/models/slider_model.dart';

void main() {
  group('SliderModel Tests', () {
    test('parses SliderModel correctly with full URL', () {
      final json = {
        'id': 1,
        'title': 'سلسلة اضاءات إسلامية في التربية الأسرية',
        'description': 'بقلم الكاتبة أمل الموسوي',
        'photo_url': 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/37.jpg',
        'book_id': 484,
        'link': 'https://alam-alislam.com',
      };

      final slider = SliderModel.fromJson(json);
      expect(slider.id, '1');
      expect(slider.title, 'سلسلة اضاءات إسلامية في التربية الأسرية');
      expect(slider.description, 'بقلم الكاتبة أمل الموسوي');
      expect(slider.imageUrl, 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/37.jpg');
      expect(slider.bookId, '484');
      expect(slider.link, 'https://alam-alislam.com');
    });

    test('prepends base url for relative image path', () {
      final json = {
        'id': 2,
        'image': 'Library/amal_islam/069/12.jpg',
      };

      final slider = SliderModel.fromJson(json);
      expect(slider.id, '2');
      expect(slider.imageUrl, 'https://library.dijlah.org/upload_list/source/Library/amal_islam/069/12.jpg');
    });
  });
}

