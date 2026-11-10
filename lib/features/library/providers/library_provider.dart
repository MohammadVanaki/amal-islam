import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/book_model.dart';
import '../data/models/category_model.dart';
import '../data/models/slider_model.dart';
import '../data/repositories/library_repository.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});

final slidersFutureProvider = FutureProvider<List<SliderModel>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return await repository.fetchSliders();
});

final booksFutureProvider = FutureProvider<List<BookModel>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return await repository.fetchBooks();
});

final categoriesFutureProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  return await repository.fetchCategories();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredBooksProvider = Provider<List<BookModel>>((ref) {
  final booksAsync = ref.watch(booksFutureProvider);
  final selectedCat = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return booksAsync.maybeWhen(
    data: (books) {
      return books.where((book) {
        final matchesCat = selectedCat == null ||
            selectedCat == 'الكل' ||
            book.category == selectedCat;

        final matchesQuery = query.isEmpty ||
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query) ||
            (book.description != null && book.description!.toLowerCase().contains(query));

        return matchesCat && matchesQuery;
      }).toList();
    },
    orElse: () => [],
  );
});

