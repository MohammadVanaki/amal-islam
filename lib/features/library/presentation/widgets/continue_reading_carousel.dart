import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../providers/annotations_provider.dart';
import '../../providers/library_provider.dart';

class ContinueReadingCarousel extends ConsumerWidget {
  final void Function(BookModel book, int initialPage) onResumeBook;

  const ContinueReadingCarousel({
    super.key,
    required this.onResumeBook,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(recentReadingHistoryProvider);
    final booksAsync = ref.watch(booksFutureProvider);

    return historyAsync.maybeWhen(
      data: (historyList) {
        if (historyList.isEmpty) return const SizedBox.shrink();

        final allBooks = booksAsync.value ?? [];
        final items = <Map<String, dynamic>>[];

        for (final item in historyList) {
          final bookId = item['book_id']?.toString();
          final book = allBooks.where((b) => b.id == bookId).firstOrNull;
          if (book != null) {
            items.add({
              'book': book,
              'last_page': item['last_page'] as int? ?? 1,
              'total_pages': item['total_pages'] as int? ?? (book.pageCount > 0 ? book.pageCount : 1),
            });
          }
        }

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: AppColors.accent, size: 16),
                  ),
                  const Gap(8),
                  const Text(
                    'متابعة القراءة',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 125,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) {
                  final data = items[index];
                  final book = data['book'] as BookModel;
                  final lastPage = data['last_page'] as int;
                  final totalPages = data['total_pages'] as int;
                  final progress = (lastPage / (totalPages > 0 ? totalPages : 1)).clamp(0.0, 1.0);
                  final percent = (progress * 100).toInt();

                  return ZoomTapAnimation(
                    onTap: () => onResumeBook(book, lastPage),
                    begin: 1.0,
                    end: 0.97,
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Book Thumbnail with 3D Spine
                          Container(
                            width: 54,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
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
                                        memCacheWidth: 150,
                                        memCacheHeight: 220,
                                        maxWidthDiskCache: 300,
                                        maxHeightDiskCache: 450,
                                        fit: BoxFit.contain,
                                        errorWidget: (context, url, error) => _buildMiniPlaceholder(book.title),
                                      )
                                    : _buildMiniPlaceholder(book.title),
                                // Spine gradient
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        stops: [0.0, 0.08, 0.3],
                                        colors: [Color(0x55000000), Color(0x22FFFFFF), Colors.transparent],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(12),
                          // Content & Progress
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Gap(2),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const Gap(6),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                                  ),
                                ),
                                const Gap(5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ص $lastPage من $totalPages',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$percent%',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Gap(4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(4),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildMiniPlaceholder(String title) {
    return Container(
      color: AppColors.primary,
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 22),
      ),
    );
  }
}
