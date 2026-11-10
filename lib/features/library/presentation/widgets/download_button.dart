import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../providers/download_provider.dart';

class DownloadButton extends ConsumerWidget {
  final BookModel book;
  final VoidCallback onRead;

  const DownloadButton({
    super.key,
    required this.book,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(singleBookDownloadProvider(book.id));
    final notifier = ref.read(downloadManagerProvider.notifier);

    if (downloadState.isDownloading) {
      final percentage = (downloadState.progress * 100).toInt();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.downloadProgress.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.downloadProgress.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(AppColors.downloadProgress),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'جاري تحميل وفهرسة النص... $percentage%',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
                  tooltip: 'إلغاء التحميل',
                  onPressed: () => notifier.cancelDownload(book.id),
                ),
              ],
            ),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: downloadState.progress > 0 ? downloadState.progress : null,
                minHeight: 7,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.downloadProgress),
              ),
            ),
          ],
        ),
      );
    }

    if (downloadState.isDownloaded) {
      return Row(
        children: [
          // Read Book Button (Text Version)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: onRead,
                icon: const Icon(Icons.menu_book_rounded, color: AppColors.accent, size: 20),
                label: const Text(
                  'قراءة الكتاب (نص كامل)',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const Gap(10),
          // Delete Book Button
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('حذف النص المحمل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  content: const Text('هل أنت متأكد من حذف النص المحمل من جهازك لتحرير المساحة؟'),
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
                        notifier.deleteBook(book);
                      },
                      child: const Text('نعم، حذف'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            tooltip: 'حذف النص',
          ),
        ],
      );
    }

    // If there was an error in previous download attempt
    if (downloadState.error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                const Gap(8),
                Expanded(
                  child: Text(
                    'تعذر تحميل النص: ${downloadState.error}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Gap(10),
          ElevatedButton.icon(
            onPressed: () => notifier.startDownload(book),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              'إعادة محاولة تحميل النص',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      );
    }

    // Not downloaded yet: Prominent download button
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => notifier.startDownload(book),
        icon: const Icon(Icons.cloud_download_rounded, color: AppColors.accent, size: 22),
        label: const Text(
          'تحميل وقراءة الكتاب (نص كامل)',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
