import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islam/features/library/data/models/book_model.dart';
import 'package:islam/features/library/data/models/category_model.dart';
import 'package:islam/features/library/presentation/screens/categories_screen.dart';
import 'package:islam/features/library/providers/download_provider.dart';
import 'package:islam/features/library/providers/library_provider.dart';

void main() {
  testWidgets('CategoriesScreen shows category name, المزيد, 3 books preview and opens full category',
      (tester) async {
    final testCategory = const CategoryModel(id: '1', name: 'أسرة');

    final testBooks = List.generate(
      5,
      (i) => BookModel(
        id: '$i',
        title: 'كتاب أسري $i',
        author: 'المؤلف $i',
        category: 'أسرة',
        coverUrl: '',
        description: 'وصف الكتاب $i',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoriesFutureProvider.overrideWith((ref) async => [testCategory]),
          booksFutureProvider.overrideWith((ref) async => testBooks),
          downloadedBooksProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CategoriesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify category header and "المزيد" button are displayed
    expect(find.text('أسرة'), findsWidgets);
    expect(find.text('المزيد'), findsOneWidget);

    // 2. Verify 3 books are displayed in the preview (and 4th slot is "عرض الكل")
    expect(find.byKey(const ValueKey('cat_1_book_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cat_1_book_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cat_1_book_2')), findsOneWidget);
    expect(find.text('عرض الكل'), findsOneWidget);

    // 3. Tap on "المزيد"
    await tester.tap(find.text('المزيد'));
    await tester.pumpAndSettle();

    // 4. Verify CategoryBooksScreen opened showing all books header
    expect(find.byType(CategoryBooksScreen), findsOneWidget);
    expect(find.text('قائمة كتب القسم'), findsOneWidget);
    expect(find.text('5 كتاب'), findsOneWidget);
  });
}

