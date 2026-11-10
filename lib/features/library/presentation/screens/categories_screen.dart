import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/main_tab_app_bar.dart';
import '../../data/models/book_model.dart';
import '../../data/models/category_model.dart';
import '../../providers/library_provider.dart';
import '../widgets/book_card.dart';
import 'book_detail_screen.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String name) {
    if (name.contains('أسرة') ||
        name.contains('تربية') ||
        name.contains('طفل') ||
        name.contains('أولاد')) {
      return Icons.family_restroom_rounded;
    } else if (name.contains('أخلاق') ||
        name.contains('سلوك') ||
        name.contains('روح')) {
      return Icons.self_improvement_rounded;
    } else if (name.contains('فقه') ||
        name.contains('شريعة') ||
        name.contains('أحكام')) {
      return Icons.balance_rounded;
    } else if (name.contains('سيرة') ||
        name.contains('تاريخ') ||
        name.contains('قصص')) {
      return Icons.history_edu_rounded;
    } else if (name.contains('قرآن') || name.contains('تفسير')) {
      return Icons.menu_book_rounded;
    } else if (name.contains('عقيدة') ||
        name.contains('فكر') ||
        name.contains('ثقافة')) {
      return Icons.lightbulb_outline_rounded;
    } else if (name.contains('اجتماع') ||
        name.contains('مجتمع') ||
        name.contains('مرأة')) {
      return Icons.groups_rounded;
    }
    return Icons.auto_stories_rounded;
  }

  void _openCategory(BuildContext context, CategoryModel category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CategoryBooksScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesFutureProvider);
    final booksAsync = ref.watch(booksFutureProvider);
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: MainTabAppBar(
        title: 'التصانيف',
        icon: Icons.category_rounded,
        badge: categoriesAsync.maybeWhen(
          data: (cats) => cats.isNotEmpty
              ? TabAppBarBadge(
                  icon: Icons.category_rounded,
                  label: '${cats.length} تصنيف',
                )
              : null,
          orElse: () => null,
        ),
      ),
      body: RefreshIndicator(
        color: currentPalette.accent,
        backgroundColor: currentPalette.color,
        onRefresh: () async {
          ref.invalidate(categoriesFutureProvider);
          ref.invalidate(booksFutureProvider);
        },
        child: categoriesAsync.when(
          loading: () => _buildShimmerSections(isDark),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const Gap(12),
                  Text(
                    'تعذر تحميل التصانيف',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Gap(16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(categoriesFutureProvider),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentPalette.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (allCategories) {
            if (allCategories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const Gap(16),
                    Text(
                      'لا توجد تصانيف متاحة حالياً',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            final allBooks = booksAsync.value ?? [];

            // Group books by category name
            final Map<String, List<BookModel>> categoryBooksMap = {};
            for (final cat in allCategories) {
              final catBooks = allBooks.where((b) {
                if (b.category == null) return false;
                return b.category!.trim().toLowerCase() ==
                    cat.name.trim().toLowerCase();
              }).toList();
              categoryBooksMap[cat.name] = catBooks;
            }

            // Filter categories based on search
            final q = _searchQuery.trim().toLowerCase();
            final visibleCategories = allCategories.where((cat) {
              if (q.isEmpty) return true;
              final matchesCategory = cat.name.toLowerCase().contains(q);
              final booksInCat = categoryBooksMap[cat.name] ?? [];
              final matchesAnyBook = booksInCat.any(
                (b) =>
                    b.title.toLowerCase().contains(q) ||
                    b.author.toLowerCase().contains(q),
              );
              return matchesCategory || matchesAnyBook;
            }).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Search Input
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                        style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن تصنيف أو كتاب...',
                          hintStyle: GoogleFonts.ibmPlexSansArabic(
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
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                  ),
                ),

                if (visibleCategories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'لا توجد تصانيف مطابقة لبحثك',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  // Category Sections
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = visibleCategories[index];
                        final catBooks = categoryBooksMap[cat.name] ?? [];
                        final previewBooks = catBooks.take(3).toList();
                        final hasMore = catBooks.length > 3;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Header: اسم المجموعة + زر المزيد
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Right: آیکون + اسم گروه + تعداد
                                    Expanded(
                                      child: InkWell(
                                        onTap: () =>
                                            _openCategory(context, cat),
                                        borderRadius: BorderRadius.circular(10),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? AppColors.cardDark
                                                      : currentPalette.color
                                                          .withValues(
                                                          alpha: 0.10,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? AppColors.borderDark
                                                        : currentPalette.color
                                                            .withValues(
                                                            alpha: 0.18,
                                                          ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    _getCategoryIcon(cat.name),
                                                    size: 16,
                                                    color: currentPalette.color,
                                                  ),
                                                ),
                                              ),
                                              const Gap(10),
                                              Flexible(
                                                child: Text(
                                                  cat.name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts
                                                      .ibmPlexSansArabic(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF1F2937,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                              const Gap(8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: currentPalette.color
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${catBooks.length}',
                                                  style: GoogleFonts
                                                      .ibmPlexSansArabic(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark
                                                        ? currentPalette
                                                            .primaryLight
                                                        : currentPalette.color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Gap(8),

                                    // Left: زر "المزيد" مع سهم
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () =>
                                            _openCategory(context, cat),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'المزيد',
                                                style: GoogleFonts
                                                    .ibmPlexSansArabic(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: currentPalette.color,
                                                ),
                                              ),
                                              const Gap(2),
                                              Icon(
                                                Icons
                                                    .arrow_forward_ios_rounded,
                                                size: 11,
                                                color: currentPalette.color,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2. کانتینر نمایش ۳ کتاب از این گروه
                              if (catBooks.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.cardDark
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'لا توجد كتب مضافة في هذا التصنيف حالياً',
                                        style: GoogleFonts.ibmPlexSansArabic(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 235,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    itemCount:
                                        previewBooks.length + (hasMore ? 1 : 0),
                                    separatorBuilder: (context, i) =>
                                        const Gap(12),
                                    itemBuilder: (context, i) {
                                      if (i < previewBooks.length) {
                                        final book = previewBooks[i];
                                        return SizedBox(
                                          width: 135,
                                          child: BookCard(
                                            key: ValueKey(
                                              'cat_${cat.id}_book_${book.id}',
                                            ),
                                            book: book,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (ctx) =>
                                                      BookDetailScreen(
                                                    book: book,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      } else {
                                        // کارت "عرض الكل" در انتهای ۳ کتاب
                                        return SizedBox(
                                          width: 110,
                                          child: _ViewAllCategoryCard(
                                            category: cat,
                                            remainingCount: catBooks.length -
                                                previewBooks.length,
                                            currentPalette: currentPalette,
                                            onTap: () =>
                                                _openCategory(context, cat),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: visibleCategories.length,
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Gap(MediaQuery.paddingOf(context).bottom + 24),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerSections(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[750]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 140,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
                SizedBox(
                  height: 235,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 3,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, _) => Container(
                      width: 135,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// کارت انتهایی اسلایدر برای نمایش همه کتاب‌های گروه
class _ViewAllCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int remainingCount;
  final AppPalette currentPalette;
  final VoidCallback onTap;

  const _ViewAllCategoryCard({
    required this.category,
    required this.remainingCount,
    required this.currentPalette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : currentPalette.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : currentPalette.color.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        currentPalette.primaryLight,
                        currentPalette.color,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentPalette.color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Gap(10),
                Text(
                  'عرض الكل',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : currentPalette.color,
                  ),
                ),
                if (remainingCount > 0) ...[
                  const Gap(2),
                  Text(
                    '+$remainingCount كتب',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// صفحه نمایش همه کتاب‌های یک گروه (CategoryBooksScreen)
class CategoryBooksScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CategoryBooksScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryBooksScreen> createState() =>
      _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends ConsumerState<CategoryBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksFutureProvider);
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.category.name,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : currentPalette.color,
          ),
        ),
      ),
      body: booksAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: currentPalette.color),
        ),
        error: (err, _) => Center(
          child: Text('حدث خطأ في جلب الكتب: $err'),
        ),
        data: (allBooks) {
          final categoryBooks = allBooks.where((b) {
            final matchesCategory = b.category?.trim().toLowerCase() ==
                widget.category.name.trim().toLowerCase();
            if (!matchesCategory) return false;
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q);
          }).toList();

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Search in category
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.ibmPlexSansArabic(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ابحث في ${widget.category.name}...',
                        hintStyle: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: currentPalette.color,
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                ),
              ),

              // Header with count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة كتب القسم',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
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
                          '${categoryBooks.length} كتاب',
                          style: GoogleFonts.ibmPlexSansArabic(
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
              if (categoryBooks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 52,
                          color: Colors.grey.shade400,
                        ),
                        const Gap(12),
                        Text(
                          'لا توجد كتب في هذا التصنيف',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isTablet ? 3 : 2,
                      childAspectRatio: isTablet ? 0.65 : 0.61,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = categoryBooks[index];
                        return BookCard(
                          key: ValueKey('cat_book_${book.id}'),
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
                      childCount: categoryBooks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
