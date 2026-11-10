import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islam/core/providers/auth_provider.dart';
import 'package:islam/features/library/data/models/book_model.dart';
import 'package:islam/features/library/data/models/category_model.dart';
import 'package:islam/features/library/data/models/slider_model.dart';
import 'package:islam/features/library/providers/annotations_provider.dart';
import 'package:islam/features/library/providers/download_provider.dart';
import 'package:islam/features/library/providers/library_provider.dart';
import 'package:islam/features/navigation/presentation/screens/main_navigation_screen.dart';

void main() {
  testWidgets('MainNavigationScreen renders 5 items and switches properly',
      (tester) async {
    final testBooks = [
      BookModel(
        id: '1',
        title: 'كتاب 1',
        author: 'المؤلف 1',
        category: 'عام',
        coverUrl: '',
        description: 'وصف',
      ),
    ];

    final testSlider = SliderModel(
      id: '1',
      title: 'سلايدر',
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
          downloadedBooksProvider.overrideWith((ref) async => []),
          totalStorageBytesProvider.overrideWith((ref) async => 0),
          recentReadingHistoryProvider.overrideWith((ref) async => []),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MainNavigationScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify all 5 nav item labels are present
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('التصانيف'), findsOneWidget);
    expect(find.text('الكتب المحملة'), findsOneWidget);
    expect(find.text('حول التطبيق'), findsOneWidget);
    expect(find.text('الاعدادات'), findsOneWidget);

    // 2. Default tab is الرئيسية (index 0)
    expect(find.text('مكتبة أمل الاسلام'), findsOneWidget);

    // 3. Switch to التصانيف (index 1)
    await tester.tap(find.text('التصانيف'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

    // 4. Switch to الكتب المحملة (floating index 2)
    await tester.tap(find.text('الكتب المحملة'));
    await tester.pumpAndSettle();
    expect(find.text('لا توجد كتب محمّلة حالياً'), findsOneWidget);

    // 5. Switch to حول التطبيق (index 3)
    await tester.tap(find.text('حول التطبيق'));
    await tester.pumpAndSettle();
    expect(find.text('سلسلة إضاءات إسلامية في التربية الأسرية'), findsOneWidget);

    // 6. Switch to الاعدادات (index 4)
    await tester.tap(find.text('الاعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('ألوان المظهر'), findsOneWidget);
  });
}
