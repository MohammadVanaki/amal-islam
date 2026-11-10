import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/library/data/models/book_model.dart';
import 'package:islam/features/library/data/models/category_model.dart';
import 'package:islam/features/library/data/models/slider_model.dart';
import 'package:islam/features/library/presentation/screens/library_home_screen.dart';
import 'package:islam/features/library/providers/annotations_provider.dart';
import 'package:islam/features/library/providers/library_provider.dart';

void main() {
  testWidgets('LibraryHomeScreen renders CustomScrollView and collapses with scroll',
      (tester) async {
    final testBooks = List.generate(
      20,
      (i) => BookModel(
        id: '$i',
        title: 'كتاب $i',
        author: 'المؤلف $i',
        category: 'عام',
        coverUrl: '',
        description: 'وصف الكتاب $i',
      ),
    );

    final testSlider = SliderModel(
      id: '1',
      title: 'عنوان السلايدر',
      imageUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          booksFutureProvider.overrideWith((ref) async => testBooks),
          categoriesFutureProvider.overrideWith(
            (ref) async => [const CategoryModel(id: '1', name: 'عام')],
          ),
          slidersFutureProvider.overrideWith((ref) async => [testSlider]),
          recentReadingHistoryProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: LibraryHomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Branding Header is present
    expect(find.text('مكتبة أمل الاسلام'), findsOneWidget);
    // TabBar has been removed
    expect(find.text('كل الكتب'), findsNothing);
    expect(find.text('الكتب المحمّلة'), findsNothing);

    // Verify CustomScrollView and SliverAppBar are present
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);

    // Verify Category chip and book items are present
    expect(find.text('الكل'), findsOneWidget);
    expect(find.byKey(const ValueKey('book_0')), findsOneWidget);

    // Drag up to scroll the books list
    await tester.drag(find.byKey(const ValueKey('book_0')), const Offset(0, -300));
    await tester.pumpAndSettle();

    // After collapse: Title is still visible and pinned
    expect(find.text('مكتبة أمل الاسلام'), findsOneWidget);
  });
}
