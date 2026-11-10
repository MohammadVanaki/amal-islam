import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/book_model.dart';
import '../../providers/annotations_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/library_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/continue_reading_carousel.dart';
import '../widgets/home_banner_slider.dart';
import 'book_detail_screen.dart';
import 'content_reader_screen.dart';
import 'pdf_reader_screen.dart';

class LibraryHomeScreen extends ConsumerStatefulWidget {
  const LibraryHomeScreen({super.key});

  @override
  ConsumerState<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends ConsumerState<LibraryHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _resumeBook(BookModel book, int initialPage) async {
    final downloaderService = ref.read(bookDownloaderServiceProvider);
    final hasText = await downloaderService.isTextDownloaded(book.id);
    final hasPdf = await downloaderService.isPdfDownloaded(book.id);

    if (!mounted) return;

    if (hasText) {
      final dbPath = await downloaderService.getBookFilePath(
        book.id,
        BookType.sqliteDatabase,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ContentReaderScreen(
            book: book,
            dbPath: dbPath,
            initialPage: initialPage,
          ),
        ),
      );
    } else if (hasPdf) {
      final pdfPath = await downloaderService.getBookFilePath(
        book.id,
        BookType.pdf,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PdfReaderScreen(
            book: book,
            filePath: pdfPath,
            initialPage: initialPage,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => BookDetailScreen(book: book)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksFutureProvider);
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final filteredBooks = ref.watch(filteredBooksProvider);
    final currentPalette = ref.watch(appPaletteProvider);
    final slidersAsync = ref.watch(slidersFutureProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [currentPalette.primaryLight, currentPalette.color],
    );

    final hasSliders = !slidersAsync.hasError &&
        (!slidersAsync.hasValue || slidersAsync.value!.isNotEmpty);
    const double toolbarHeight = 62.0;
    const double sliderHeight = 157.0;
    final double expandedHeight =
        toolbarHeight + (hasSliders ? sliderHeight : 0.0);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: currentPalette.accent,
          backgroundColor: currentPalette.color,
          onRefresh: () async {
            ref.invalidate(booksFutureProvider);
            ref.invalidate(categoriesFutureProvider);
            ref.invalidate(recentReadingHistoryProvider);
            ref.invalidate(slidersFutureProvider);
          },
          child: CustomScrollView(
            cacheExtent: 600,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                toolbarHeight: toolbarHeight,
                expandedHeight: expandedHeight,
                titleSpacing: 16,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Image.asset(
                        'assets/image/appIcon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: currentPalette.accent,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'مكتبة أمل الاسلام',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color:
                                  isDark ? Colors.white : currentPalette.color,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'سلسلة اضاءات إسلامية في التربية الأسرية',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                flexibleSpace: hasSliders
                    ? FlexibleSpaceBar(
                        collapseMode: CollapseMode.parallax,
                        background: Padding(
                          padding: const EdgeInsets.only(top: toolbarHeight),
                          child: const ClipRect(
                            child: OverflowBox(
                              minHeight: 0,
                              maxHeight: sliderHeight,
                              alignment: Alignment.topCenter,
                              child: HomeBannerSlider(),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),

              // Floating Capsule Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentPalette.color.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن كتاب، مؤلف، أو موضوع...',
                        hintStyle: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: currentPalette.color,
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),

              // Luxury Category Chips
              SliverToBoxAdapter(
                child: categoriesAsync.maybeWhen(
                  data: (categories) {
                    final allList = [
                      const StringAndCount(name: 'الكل'),
                      ...categories.map(
                        (c) => StringAndCount(name: c.name, count: c.bookCount),
                      ),
                    ];

                    return SizedBox(
                      height: 38,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: allList.length,
                        separatorBuilder: (context, index) => const Gap(8),
                        itemBuilder: (context, index) {
                          final item = allList[index];
                          final isSelected =
                              (selectedCategory == null &&
                                  item.name == 'الكل') ||
                              selectedCategory == item.name;

                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = item.name == 'الكل'
                                  ? null
                                  : item.name;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected ? primaryGradient : null,
                                color: isSelected
                                    ? null
                                    : (isDark
                                          ? AppColors.cardDark
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? currentPalette.accent.withValues(
                                          alpha: 0.5,
                                        )
                                      : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight),
                                  width: 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: currentPalette.color
                                              .withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: currentPalette.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Gap(6),
                                  ],
                                  Text(
                                    item.count != null && item.count! > 0
                                        ? '${item.name} (${item.count})'
                                        : item.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.grey.shade300
                                                : AppColors.textPrimaryLight),
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),

              const SliverToBoxAdapter(child: Gap(12)),

              // Continue Reading Carousel (Hero)
              SliverToBoxAdapter(
                child: ContinueReadingCarousel(
                  onResumeBook: (book, page) => _resumeBook(book, page),
                ),
              ),

              // Book Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: currentPalette.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            'قائمة الكتب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: currentPalette.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${filteredBooks.length} كتاب',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? currentPalette.primaryLight
                                : currentPalette.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Books Grid
              booksAsync.when(
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: currentPalette.color,
                    ),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: currentPalette.color.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.wifi_off_rounded,
                              size: 40,
                              color: currentPalette.color,
                            ),
                          ),
                          const Gap(16),
                          const Text(
                            'تعذر الاتصال بالخادم، تم تفعيل الوضع المحلي',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Gap(14),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            onPressed: () => ref.refresh(booksFutureProvider),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                data: (_) {
                  if (filteredBooks.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('لا توجد كتب مطابقة لبحثك')),
                    );
                  }

                  final screenWidth = MediaQuery.sizeOf(context).width;
                  final isTablet = screenWidth >= 600;
                  final crossAxisCount = isTablet ? 3 : 2;
                  final childAspectRatio = isTablet ? 0.65 : 0.61;

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final book = filteredBooks[index];
                          return BookCard(
                            key: ValueKey('book_${book.id}'),
                            book: book,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) =>
                                      BookDetailScreen(book: book),
                                ),
                              );
                            },
                          );
                        },
                        childCount: filteredBooks.length,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                      ),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: Gap(MediaQuery.paddingOf(context).bottom + 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StringAndCount {
  final String name;
  final int? count;
  const StringAndCount({required this.name, this.count});
}
