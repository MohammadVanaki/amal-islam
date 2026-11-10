import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';
import '../models/slider_model.dart';

class LibraryRepository {
  final Dio _dio = DioClient.instance.dio;

  static const String _cachedBooksKey = 'cached_dijlah_books_v1';
  static const String _cachedCategoriesKey = 'cached_dijlah_categories_v1';
  static const String _cachedSlidersKey = 'cached_dijlah_sliders_v1';

  Future<List<BookModel>> fetchBooks() async {
    try {
      final response = await _dio.get(ApiConstants.booksEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        List<dynamic> list = [];

        if (data is Map && data['books'] is List) {
          list = data['books'];
        } else if (data is List) {
          list = data;
        } else if (data is Map && data['data'] is List) {
          list = data['data'];
        }

        if (list.isNotEmpty) {
          final books = list.map((item) => BookModel.fromJson(item as Map<String, dynamic>)).toList();
          developer.log('Fetched ${books.length} books from Dijlah API', name: 'LibraryRepository');

          _cacheBooks(books);

          if (data is Map && data['categories'] is List) {
            final List<dynamic> catList = data['categories'];
            final categories = catList.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
            _cacheCategories(categories);
          }

          return books;
        }
      }
    } catch (e) {
      final reason = e is DioException
          ? 'Dio error [${e.response?.statusCode ?? e.type.name}]: ${e.message}'
          : e.toString();
      developer.log(
        'Dijlah API unavailable ($reason). Falling back to local cache/fallback.',
        name: 'LibraryRepository',
      );
    }

    final cached = await _getCachedBooks();
    if (cached != null && cached.isNotEmpty) {
      developer.log('Loaded ${cached.length} books from local offline cache', name: 'LibraryRepository');
      return cached;
    }

    return fallbackBooks;
  }

  Future<void> _cacheBooks(List<BookModel> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(books.map((b) => b.toJson()).toList());
      await prefs.setString(_cachedBooksKey, jsonStr);
    } catch (_) {}
  }

  Future<List<BookModel>?> _getCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedBooksKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.map((item) => BookModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<BookModel?> fetchBookDetails(String bookId) async {
    try {
      final response = await _dio.get('/book/$bookId');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        if (data is Map && data['book'] != null) {
          return BookModel.fromJson(data['book'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      developer.log('Error fetching book $bookId details: $e', name: 'LibraryRepository');
    }
    return null;
  }

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _dio.get(ApiConstants.booksEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        if (data is Map && data['categories'] is List) {
          final List<dynamic> catList = data['categories'];
          final categories = catList.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
          _cacheCategories(categories);
          return categories;
        }
      }
    } catch (_) {}

    final cached = await _getCachedCategories();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    return [
      const CategoryModel(id: '10', name: 'قضايا اسلامية', bookCount: 10),
    ];
  }

  Future<void> _cacheCategories(List<CategoryModel> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(categories.map((c) => c.toJson()).toList());
      await prefs.setString(_cachedCategoriesKey, jsonStr);
    } catch (_) {}
  }

  Future<List<CategoryModel>?> _getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedCategoriesKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.map((item) => CategoryModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<SliderModel>> fetchSliders() async {
    try {
      final response = await _dio.get(ApiConstants.homeEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        if (data is Map && data['sliders'] is List) {
          final List<dynamic> list = data['sliders'];
          if (list.isNotEmpty) {
            final sliders = list
                .whereType<Map<String, dynamic>>()
                .map((item) => SliderModel.fromJson(item))
                .where((s) => s.imageUrl.isNotEmpty)
                .toList();
            if (sliders.isNotEmpty) {
              developer.log('Fetched ${sliders.length} sliders from Dijlah API', name: 'LibraryRepository');
              _cacheSliders(sliders);
              return sliders;
            }
          }
        }
      }
    } catch (e) {
      final reason = e is DioException
          ? 'Dio error [${e.response?.statusCode ?? e.type.name}]: ${e.message}'
          : e.toString();
      developer.log(
        'Dijlah Sliders API unavailable ($reason). Falling back to local cache/fallback.',
        name: 'LibraryRepository',
      );
    }

    final cached = await _getCachedSliders();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    return fallbackSliders;
  }

  Future<void> _cacheSliders(List<SliderModel> sliders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(sliders.map((s) => s.toJson()).toList());
      await prefs.setString(_cachedSlidersKey, jsonStr);
    } catch (_) {}
  }

  Future<List<SliderModel>?> _getCachedSliders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedSlidersKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.map((item) => SliderModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return null;
  }

  static final List<SliderModel> fallbackSliders = [
    const SliderModel(
      id: '1',
      title: 'سلسلة اضاءات إسلامية في التربية الأسرية',
      description: 'بقلم الكاتبة أمل الموسوي — رؤية تربوية معاصرة مستمدة من القيم الأصيلة',
      imageUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/37.jpg',
      bookId: '484',
      link: 'https://alam-alislam.com',
      actionText: 'استعراض الكتاب',
    ),
    const SliderModel(
      id: '2',
      title: 'الصــدق رأس الإيـمان',
      description: 'إصدار متميز يناقش ركائز الأخلاق والصدق في السلوك الإنساني والتربوي',
      imageUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/069/12.jpg',
      bookId: '544',
      link: 'https://alam-alislam.com',
      actionText: 'قراءة الكتاب',
    ),
    const SliderModel(
      id: '3',
      title: 'مكتبة أمل الاسلام الرقمية',
      description: 'تجربة قراءة تفاعلية مع خطوط عربية أصيلة وحفظ الملاحظات والمواضع',
      imageUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/01/28.jpg',
      bookId: '475',
      link: 'https://alam-alislam.com',
      actionText: 'اكتشف المزيد',
    ),
  ];

  static final List<BookModel> fallbackBooks = [
    const BookModel(
      id: '484',
      title: 'اضاءات إسلامية في التربية الأسرية (الجزء 10)',
      author: 'أمل الموسوي',
      category: 'قضايا اسلامية',
      description: 'سلسلة اضاءات إسلامية في التربية الأسرية بقلم الكاتبة أمل الموسوي.',
      coverUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/37.jpg',
      pdfUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/010.pdf',
      txtUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/010/453.txt',
      pageCount: 43,
      rating: 5.0,
    ),
    const BookModel(
      id: '475',
      title: 'اضاءات إسلامية في التربية الأسرية (الجزء 1)',
      author: 'أمل الموسوي',
      category: 'قضايا اسلامية',
      description: 'سلسلة اضاءات إسلامية في التربية الأسرية بقلم الكاتبة أمل الموسوي.',
      coverUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/01/28.jpg',
      pdfUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/01/001.pdf',
      txtUrl: 'https://library.dijlah.org/upload_list/source/Library/amal_islam/01/444.txt',
      pageCount: 51,
      rating: 5.0,
    ),
  ];
}
