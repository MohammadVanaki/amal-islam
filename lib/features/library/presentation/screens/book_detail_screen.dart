import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/book_model.dart';
import '../../providers/annotations_provider.dart';
import '../../providers/download_provider.dart';
import 'content_reader_screen.dart';
import 'pdf_reader_screen.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(downloadManagerProvider.notifier).checkAllStatuses(widget.book.id);
    });
  }

  Future<void> _openTextReader() async {
    final downloaderService = ref.read(bookDownloaderServiceProvider);
    final filePath = await downloaderService.getBookFilePath(widget.book.id, BookType.sqliteDatabase);

    final progress = await ref.read(annotationsDbServiceProvider).getReadingProgress(widget.book.id);
    final initialPage = progress != null ? (progress['last_page'] as int? ?? 1) : 1;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ContentReaderScreen(
          book: widget.book,
          dbPath: filePath,
          initialPage: initialPage,
        ),
      ),
    );
  }

  Future<void> _openPdfReader() async {
    final downloaderService = ref.read(bookDownloaderServiceProvider);
    final filePath = await downloaderService.getBookFilePath(widget.book.id, BookType.pdf);

    final progress = await ref.read(annotationsDbServiceProvider).getReadingProgress(widget.book.id);
    final initialPage = progress != null ? (progress['last_page'] as int? ?? 1) : 1;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PdfReaderScreen(
          book: widget.book,
          filePath: filePath,
          initialPage: initialPage,
        ),
      ),
    );
  }

  void _shareBook() {
    Share.share(
      'كتاب: ${widget.book.title}\n'
      'تأليف: ${widget.book.author}\n'
      'من مكتبة أمل الإسلام الإلكترونية 📚\n'
      'https://alam-alislam.com',
      subject: widget.book.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final textDownloadState = ref.watch(singleBookDownloadProvider(book.id));
    final pdfDownloadState = ref.watch(singlePdfDownloadProvider(book.id));
    final downloadNotifier = ref.read(downloadManagerProvider.notifier);
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Elegant Header with Soft Palette Gradient & Natural Book Cover
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: currentPalette.color,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, size: 22),
                tooltip: 'مشاركة الكتاب',
                onPressed: _shareBook,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [
                            AppColors.cardDark,
                            Theme.of(context).scaffoldBackgroundColor,
                          ]
                        : [
                            currentPalette.color.withValues(alpha: 0.16),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48.0, bottom: 16.0),
                    child: Container(
                      width: 145,
                      height: 215,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          book.coverUrl != null && book.coverUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: book.coverUrl!,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                  errorWidget: (context, url, error) => _buildPlaceholder(currentPalette),
                                )
                              : _buildPlaceholder(currentPalette),

                          // Subtle book spine highlight on left
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            width: 8,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0x33000000), Color(0x15FFFFFF), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Book Info & Reading Hub
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Title & Author
                  Center(
                    child: Column(
                      children: [
                        Text(
                          book.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF151817),
                            height: 1.35,
                          ),
                        ),
                        const Gap(6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 16,
                              color: currentPalette.color,
                            ),
                            const Gap(6),
                            Text(
                              book.author,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(18),

                  // Quick Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentPalette.color.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatTile(
                          icon: Icons.pages_outlined,
                          title: 'الصفحات',
                          value: book.pageCount > 0 ? '${book.pageCount}' : 'غير محدد',
                          color: currentPalette.color,
                        ),
                        Container(width: 1, height: 28, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        _buildStatTile(
                          icon: Icons.category_outlined,
                          title: 'التصنيف',
                          value: book.category ?? 'عام',
                          color: currentPalette.color,
                        ),
                        Container(width: 1, height: 28, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        _buildStatTile(
                          icon: Icons.star_rounded,
                          title: 'التقييم',
                          value: book.rating.toStringAsFixed(1),
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                  const Gap(22),

                  // Minimal Action Buttons (دکمه‌های مینیمال، مدرن و متقارن)
                  Row(
                    children: [
                      // 1. Text Action Button (Primary)
                      Expanded(
                        child: _buildMinimalButton(
                          icon: Icons.auto_stories_rounded,
                          label: textDownloadState.isDownloaded
                              ? 'قراءة النص'
                              : (textDownloadState.isDownloading
                                  ? 'تحميل'
                                  : 'تحميل وقراءة'),
                          isPrimary: true,
                          isDownloaded: textDownloadState.isDownloaded,
                          isDownloading: textDownloadState.isDownloading,
                          progress: textDownloadState.progress,
                          color: currentPalette.color,
                          isDark: isDark,
                          onTap: () async {
                            if (textDownloadState.isDownloaded) {
                              _openTextReader();
                            } else if (!textDownloadState.isDownloading) {
                              final messenger = ScaffoldMessenger.of(context);
                              await downloadNotifier.startDownload(book);
                              if (!mounted) return;
                              if (ref.read(singleBookDownloadProvider(book.id)).isDownloaded) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('تم اكتمال تحميل نص الكتاب بنجاح'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          onCancel: () {
                            downloadNotifier.cancelDownload(book.id);
                          },
                        ),
                      ),

                      // 2. PDF Action Button (Secondary)
                      if (book.hasPdf) ...[
                        const Gap(10),
                        Expanded(
                          child: _buildMinimalButton(
                            icon: Icons.picture_as_pdf_rounded,
                            label: pdfDownloadState.isDownloaded
                                ? 'فتح PDF'
                                : (pdfDownloadState.isDownloading
                                    ? 'تحميل'
                                    : 'نسخة PDF'),
                            isPrimary: false,
                            isDownloaded: pdfDownloadState.isDownloaded,
                            isDownloading: pdfDownloadState.isDownloading,
                            progress: pdfDownloadState.progress,
                            color: const Color(0xFFD32F2F),
                            isDark: isDark,
                            onTap: () async {
                              if (pdfDownloadState.isDownloaded) {
                                _openPdfReader();
                              } else if (!pdfDownloadState.isDownloading) {
                                final messenger = ScaffoldMessenger.of(context);
                                await downloadNotifier.startDownloadPdf(book);
                                if (!mounted) return;
                                if (ref.read(singlePdfDownloadProvider(book.id)).isDownloaded) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('تم اكتمال تحميل نسخة PDF بنجاح'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            onCancel: () {
                              downloadNotifier.cancelDownload('pdf_${book.id}');
                            },
                          ),
                        ),
                      ],

                      // 3. Delete Action (discreet icon only when downloaded)
                      if (textDownloadState.isDownloaded || pdfDownloadState.isDownloaded) ...[
                        const Gap(8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(alpha: 0.08),
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          tooltip: 'حذف المحتوى المحمل',
                          onPressed: () => _confirmDelete(
                            context,
                            title: 'حذف المحتوى المحمل',
                            message: 'هل ترغب في حذف ملفات هذا الكتاب من جهازك لتحرير المساحة؟',
                            onConfirmed: () {
                              if (textDownloadState.isDownloaded) downloadNotifier.deleteBook(book);
                              if (pdfDownloadState.isDownloaded) downloadNotifier.deletePdf(book);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(24),

                  // Description Card (نبذة عن الكتاب)
                  Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 16,
                        decoration: BoxDecoration(
                          color: currentPalette.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Gap(8),
                      const Text(
                        'نبذة عن الكتاب',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: currentPalette.color.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      (book.description != null && book.description!.isNotEmpty)
                          ? book.description!
                          : 'سلسلة إضاءات إسلامية في التربية الأسرية بقلم الكاتبة أمل الموسوي، تهدف إلى بناء وتطوير الأسرة المسلمة ومعالجة القضايا التربوية والسلوكية وفق منهج أهل البيت عليهم السلام.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.8,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Gap(MediaQuery.paddingOf(context).bottom + 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// دکمه مینیمال و شکیل با انیمیشن لودینگ و ارتفاع استاندارد همراه با دکمه لغو
  Widget _buildMinimalButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isDownloaded,
    required bool isDownloading,
    required double progress,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    VoidCallback? onCancel,
  }) {
    final percentage = (progress * 100).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDownloading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary
                ? color
                : (isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isPrimary ? Colors.transparent : color.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: isDownloading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(isPrimary ? Colors.white : color),
                          ),
                        ),
                        const Gap(6),
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPrimary ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                    if (onCancel != null)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onCancel,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: (isPrimary ? Colors.white : color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (isPrimary ? Colors.white : color).withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 13,
                                  color: isPrimary ? Colors.white : color,
                                ),
                                const Gap(3),
                                Text(
                                  'إلغاء',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isPrimary ? Colors.white : color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 19,
                      color: isPrimary ? Colors.white : color,
                    ),
                    const Gap(8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isPrimary ? Colors.white : color,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirmed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmed();
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(AppPalette palette) {
    return Container(
      color: palette.color,
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 40),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(4),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const Gap(2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
