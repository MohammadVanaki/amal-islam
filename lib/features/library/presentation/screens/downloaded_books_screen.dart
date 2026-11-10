import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/main_tab_app_bar.dart';
import '../../data/models/book_model.dart';
import '../../providers/annotations_provider.dart';
import '../../providers/download_provider.dart';
import 'book_detail_screen.dart';
import 'content_reader_screen.dart';
import 'pdf_reader_screen.dart';

class DownloadedBooksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBrowseBooks;

  const DownloadedBooksScreen({
    super.key,
    this.onBrowseBooks,
  });

  @override
  ConsumerState<DownloadedBooksScreen> createState() =>
      _DownloadedBooksScreenState();
}

class _DownloadedBooksScreenState extends ConsumerState<DownloadedBooksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openTextReader(BookModel book) async {
    final downloaderService = ref.read(bookDownloaderServiceProvider);
    final filePath = await downloaderService.getBookFilePath(
      book.id,
      BookType.sqliteDatabase,
    );

    final progress = await ref
        .read(annotationsDbServiceProvider)
        .getReadingProgress(book.id);
    final initialPage =
        progress != null ? (progress['last_page'] as int? ?? 1) : 1;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ContentReaderScreen(
          book: book,
          dbPath: filePath,
          initialPage: initialPage,
        ),
      ),
    );
  }

  Future<void> _openPdfReader(BookModel book) async {
    final downloaderService = ref.read(bookDownloaderServiceProvider);
    final filePath =
        await downloaderService.getBookFilePath(book.id, BookType.pdf);

    final progress = await ref
        .read(annotationsDbServiceProvider)
        .getReadingProgress(book.id);
    final initialPage =
        progress != null ? (progress['last_page'] as int? ?? 1) : 1;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PdfReaderScreen(
          book: book,
          filePath: filePath,
          initialPage: initialPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloadedBooksAsync = ref.watch(downloadedBooksProvider);
    final totalBytesAsync = ref.watch(totalStorageBytesProvider);
    final downloaderService = ref.watch(bookDownloaderServiceProvider);
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [currentPalette.primaryLight, currentPalette.color],
    );

    return Scaffold(
      appBar: MainTabAppBar(
        title: 'الكتب المحمّلة',
        icon: Icons.download_done_rounded,
        badge: totalBytesAsync.maybeWhen(
          data: (bytes) => TabAppBarBadge(
            icon: Icons.storage_rounded,
            label: _formatBytes(bytes),
          ),
          orElse: () => null,
        ),
      ),
      body: downloadedBooksAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => Center(
          child: CircularProgressIndicator(color: currentPalette.color),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'حدث خطأ في جلب الكتب المحملة: $err',
              style: GoogleFonts.ibmPlexSansArabic(),
            ),
          ),
        ),
        data: (allBooks) {
          if (allBooks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: currentPalette.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_download_outlined,
                        size: 44,
                        color: currentPalette.color,
                      ),
                    ),
                    const Gap(20),
                    Text(
                      'لا توجد كتب محمّلة حالياً',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'يمكنك تصفح المكتبة وتحميل الكتب لتتمكن من قراءتها في أي وقت دون الحاجة إلى اتصال بالإنترنت.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    const Gap(24),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (widget.onBrowseBooks != null) {
                          widget.onBrowseBooks!();
                        } else {
                          Navigator.maybePop(context);
                        }
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(
                        'تصفح قائمة الكتب',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPalette.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final books = allBooks.where((b) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q);
          }).toList();

          return RefreshIndicator(
            color: currentPalette.accent,
            backgroundColor: currentPalette.color,
            onRefresh: () async {
              ref.invalidate(downloadedBooksProvider);
              ref.invalidate(totalStorageBytesProvider);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                // Storage Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: isDark
                          ? [AppColors.cardDark, AppColors.surfaceDark]
                          : [
                              currentPalette.color.withValues(alpha: 0.12),
                              currentPalette.color.withValues(alpha: 0.04),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: currentPalette.color.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentPalette.color.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: currentPalette.color.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.cloud_done_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المساحة المستخدمة للكتب المحمّلة',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const Gap(2),
                            SizedBox(
                              height: 24,
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  _formatBytes(
                                    totalBytesAsync.valueOrNull ?? 0,
                                  ),
                                  style: GoogleFonts.ibmPlexSansArabic(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? currentPalette.primaryLight
                                        : currentPalette.color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: currentPalette.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentPalette.color.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.offline_pin_rounded,
                              size: 14,
                              color: currentPalette.color,
                            ),
                            const Gap(4),
                            Text(
                              '${allBooks.length} كتب',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? currentPalette.primaryLight
                                    : currentPalette.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),

                // Search Bar in Downloaded Books
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.ibmPlexSansArabic(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'ابحث في الكتب المحملة...',
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
                              icon: const Icon(Icons.clear_rounded, size: 18),
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
                const Gap(14),

                // List of downloaded books
                if (books.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'لا توجد نتائج تطابق بحثك',
                        style: GoogleFonts.ibmPlexSansArabic(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(books.length, (index) {
                    final book = books[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: FutureBuilder<List<bool>>(
                        future: Future.wait([
                          downloaderService.isTextDownloaded(book.id),
                          downloaderService.isPdfDownloaded(book.id),
                        ]),
                        builder: (context, snapshot) {
                          final isTextDownloaded = snapshot.data?[0] ?? false;
                          final isPdfDownloaded = snapshot.data?[1] ?? false;

                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : currentPalette.color
                                        .withValues(alpha: 0.1),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        BookDetailScreen(book: book),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Thumbnail Cover
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            width: 60,
                                            height: 84,
                                            color: currentPalette.color
                                                .withValues(alpha: 0.1),
                                            child: book.coverUrl != null &&
                                                    book.coverUrl!.isNotEmpty
                                                ? CachedNetworkImage(
                                                    imageUrl: book.coverUrl!,
                                                    fit: BoxFit.cover,
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Icon(
                                                      Icons.menu_book_rounded,
                                                      color:
                                                          currentPalette.color,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.menu_book_rounded,
                                                    color: currentPalette.color,
                                                  ),
                                          ),
                                        ),
                                        const Gap(12),
                                        // Title, Author & Badges
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                book.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts
                                                    .ibmPlexSansArabic(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Gap(4),
                                              Text(
                                                book.author,
                                                style: GoogleFonts
                                                    .ibmPlexSansArabic(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const Gap(8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  if (isTextDownloaded)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.success
                                                            .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            size: 12,
                                                            color:
                                                                AppColors
                                                                    .success,
                                                          ),
                                                          const Gap(4),
                                                          Text(
                                                            'نسخة نصية',
                                                            style: GoogleFonts
                                                                .ibmPlexSansArabic(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .success,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  if (isPdfDownloaded)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.red.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .picture_as_pdf_rounded,
                                                            size: 12,
                                                            color: Colors
                                                                .red.shade700,
                                                          ),
                                                          const Gap(4),
                                                          Text(
                                                            'نسخة PDF',
                                                            style: GoogleFonts
                                                                .ibmPlexSansArabic(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .red.shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Delete Button
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                          ),
                                          tooltip: 'حذف',
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: Text(
                                                  'حذف الكتاب المحمل',
                                                  style: GoogleFonts
                                                      .ibmPlexSansArabic(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Text(
                                                  'هل ترغب في حذف ملفات كتاب "${book.title}" من جهازك؟',
                                                  style: GoogleFonts
                                                      .ibmPlexSansArabic(),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child: Text(
                                                      'إلغاء',
                                                      style: GoogleFonts
                                                          .ibmPlexSansArabic(),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      Navigator.pop(ctx);
                                                      if (isTextDownloaded) {
                                                        await ref
                                                            .read(
                                                              downloadManagerProvider
                                                                  .notifier,
                                                            )
                                                            .deleteBook(book);
                                                      }
                                                      if (isPdfDownloaded) {
                                                        await ref
                                                            .read(
                                                              downloadManagerProvider
                                                                  .notifier,
                                                            )
                                                            .deletePdf(book);
                                                      }
                                                      ref.invalidate(
                                                        downloadedBooksProvider,
                                                      );
                                                      ref.invalidate(
                                                        totalStorageBytesProvider,
                                                      );
                                                    },
                                                    child: Text(
                                                      'حذف',
                                                      style: GoogleFonts
                                                          .ibmPlexSansArabic(
                                                        color: AppColors.error,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const Gap(12),
                                    const Divider(height: 1),
                                    const Gap(8),
                                    // Action Buttons
                                    Row(
                                      children: [
                                        if (isTextDownloaded)
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _openTextReader(book),
                                              icon: const Icon(
                                                Icons.menu_book_rounded,
                                                size: 16,
                                              ),
                                              label: Text(
                                                'قراءة النص',
                                                style: GoogleFonts
                                                    .ibmPlexSansArabic(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    currentPalette.color,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (isTextDownloaded && isPdfDownloaded)
                                          const Gap(8),
                                        if (isPdfDownloaded)
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _openPdfReader(book),
                                              icon: const Icon(
                                                Icons.picture_as_pdf_rounded,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              label: Text(
                                                'فتح PDF',
                                                style: GoogleFonts
                                                    .ibmPlexSansArabic(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(
                                                  color: Colors.red.shade300,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
