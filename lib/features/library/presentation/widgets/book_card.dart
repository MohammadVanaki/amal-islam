import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/book_model.dart';
import '../../providers/download_provider.dart';

class BookCard extends ConsumerStatefulWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  ConsumerState<BookCard> createState() => _BookCardState();
}

class _BookCardState extends ConsumerState<BookCard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(downloadManagerProvider.notifier).checkStatus(
            widget.book.id,
            widget.book.bookType,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(singleBookDownloadProvider(widget.book.id));
    final currentPalette = ref.watch(appPaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Cover - 100% completely visible with BoxFit.contain (بدون برش تصویر)
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.book.coverUrl!,
                                  memCacheWidth: 320,
                                  memCacheHeight: 460,
                                  maxWidthDiskCache: 600,
                                  maxHeightDiskCache: 900,
                                  fit: BoxFit.contain, // نمایش کامل و بدون برش تصویر جلد
                                  alignment: Alignment.center,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E2422) : const Color(0xFFF3F5F4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: currentPalette.color.withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => _buildPlaceholder(currentPalette),
                                )
                              : _buildPlaceholder(currentPalette),
                        ),
                      ),

                    // Download status badge (تنها در صورت دانلود یا در حال دانلود)
                    if (downloadState.isDownloaded || downloadState.isDownloading)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: downloadState.isDownloaded
                                ? AppColors.success.withValues(alpha: 0.95)
                                : AppColors.downloadProgress.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                downloadState.isDownloaded
                                    ? Icons.check_circle_rounded
                                    : Icons.downloading_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                              const Gap(2),
                              Text(
                                downloadState.isDownloaded
                                    ? 'محمل'
                                    : '${(downloadState.progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Book Details (Title, Author, Category, Rating)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const Gap(3),
                      Expanded(
                        child: Text(
                          widget.book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.book.category != null && widget.book.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: currentPalette.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            widget.book.category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? currentPalette.primaryLight : currentPalette.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accent, size: 12),
                          const Gap(2),
                          Text(
                            widget.book.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildPlaceholder(AppPalette palette) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [palette.primaryLight, palette.color],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const Gap(4),
              Text(
                widget.book.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
