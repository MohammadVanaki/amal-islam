import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/note_model.dart';
import '../../data/services/book_content_db_service.dart';
import '../../providers/annotations_provider.dart';
import '../../providers/reader_settings_provider.dart';

class BookmarkNotesSheet extends ConsumerWidget {
  final String bookId;
  final List<BookChapter> chapters;
  final int currentPage;
  final void Function(int pageNumber) onPageSelected;

  const BookmarkNotesSheet({
    super.key,
    required this.bookId,
    this.chapters = const [],
    this.currentPage = 1,
    required this.onPageSelected,
  });

  void _openNoteEditor(
    BuildContext context,
    WidgetRef ref, {
    NoteModel? existingNote,
  }) {
    final settings = ref.read(readerSettingsProvider);
    final noteController = TextEditingController(text: existingNote?.note ?? '');
    final quoteController = TextEditingController(text: existingNote?.selectedText ?? '');
    final pageController = TextEditingController(
      text: (existingNote?.pageNumber ?? currentPage).toString(),
    );
    String selectedColor = existingNote?.colorHex ?? '0x66FFEB3B';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                existingNote != null ? Icons.edit_note_rounded : Icons.add_comment_rounded,
                color: AppColors.accent,
                size: 24,
              ),
              const Gap(8),
              Text(
                existingNote != null ? 'تعديل الملاحظة' : 'إضافة ملاحظة وتعليق',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Number Field
                TextField(
                  controller: pageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'رقم الصفحة',
                    prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const Gap(12),

                // Note / Comment Field
                TextField(
                  controller: noteController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'نص الملاحظة أو التعليق',
                    hintText: 'اكتب فائدتك، تعليقك أو ملاحظتك هنا...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  maxLines: 3,
                ),
                const Gap(12),

                // Optional Quote Field
                TextField(
                  controller: quoteController,
                  decoration: InputDecoration(
                    labelText: 'نص مقتبس من الكتاب (اختياري)',
                    hintText: 'مثلاً: جملة مميزة من الصفحة...',
                    prefixIcon: const Icon(Icons.format_quote_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
                const Gap(14),

                // Color Picker
                const Text('لون التمييز:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _colorCircle(
                      color: AppColors.highlightYellow,
                      hex: '0x66FFEB3B',
                      selected: selectedColor == '0x66FFEB3B',
                      onSelect: () => setDialogState(() => selectedColor = '0x66FFEB3B'),
                    ),
                    _colorCircle(
                      color: AppColors.highlightGreen,
                      hex: '0x664CAF50',
                      selected: selectedColor == '0x664CAF50',
                      onSelect: () => setDialogState(() => selectedColor = '0x664CAF50'),
                    ),
                    _colorCircle(
                      color: AppColors.highlightBlue,
                      hex: '0x662196F3',
                      selected: selectedColor == '0x662196F3',
                      onSelect: () => setDialogState(() => selectedColor = '0x662196F3'),
                    ),
                    _colorCircle(
                      color: AppColors.highlightPink,
                      hex: '0x66E91E63',
                      selected: selectedColor == '0x66E91E63',
                      onSelect: () => setDialogState(() => selectedColor = '0x66E91E63'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.primaryButtonColor,
                foregroundColor: settings.primaryButtonTextColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final noteText = noteController.text.trim();
                final quoteText = quoteController.text.trim();
                final pageNum = int.tryParse(pageController.text.trim()) ?? currentPage;

                if (noteText.isEmpty && quoteText.isEmpty) {
                  return;
                }

                Navigator.pop(ctx);
                final notifier = ref.read(notesProvider(bookId).notifier);

                if (existingNote != null && existingNote.id != null) {
                  final updated = NoteModel(
                    id: existingNote.id,
                    bookId: bookId,
                    pageNumber: pageNum,
                    selectedText: quoteText.isNotEmpty ? quoteText : existingNote.selectedText,
                    note: noteText,
                    colorHex: selectedColor,
                    createdAt: existingNote.createdAt,
                  );
                  await notifier.updateNote(updated);
                } else {
                  await notifier.addNote(
                    pageNumber: pageNum,
                    selectedText: quoteText.isNotEmpty ? quoteText : 'ملاحظة على صفحة $pageNum',
                    note: noteText,
                    colorHex: selectedColor,
                  );
                }
              },
              child: Text(existingNote != null ? 'تحديث' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorCircle({
    required Color color,
    required String hex,
    required bool selected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: selected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(readerSettingsProvider);
    final bookmarks = ref.watch(bookmarksProvider(bookId));
    final notes = ref.watch(notesProvider(bookId));
    final hasChapters = chapters.isNotEmpty;

    return DefaultTabController(
      length: hasChapters ? 3 : 2,
      child: Material(
        color: settings.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: SafeArea(
            top: false,
            child: Column(
            children: [
              const Gap(12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(8),
              TabBar(
                indicatorColor: settings.primaryButtonColor,
                labelColor: settings.primaryButtonColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  if (hasChapters)
                    Tab(
                      icon: const Icon(Icons.menu_book_rounded),
                      text: 'الفهرس (${chapters.length})',
                    ),
                  Tab(
                    icon: const Icon(Icons.bookmark_rounded),
                    text: 'إشارات مرجعية (${bookmarks.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.note_alt_rounded),
                    text: 'الملاحظات (${notes.length})',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // 1. Chapters / Table of Contents Tab
                    if (hasChapters)
                      ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: chapters.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final ch = chapters[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${ch.pageNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              ch.title,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(context);
                              onPageSelected(ch.pageNumber);
                            },
                          );
                        },
                      ),

                    // 2. Bookmarks Tab
                    bookmarks.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.grey),
                                  Gap(12),
                                  Text(
                                    'لا توجد إشارات مرجعية محفوظة بعد.\nاضغط على أيقونة الإشارة المرجعية أثناء القراءة.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookmarks.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final b = bookmarks[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                                  child: Text(
                                    '${b.pageNumber}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  b.title ?? 'صفحة ${b.pageNumber}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: b.snippet != null && b.snippet!.isNotEmpty
                                    ? Text(
                                        b.snippet!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                  onPressed: () {
                                    if (b.id != null) {
                                      ref.read(bookmarksProvider(bookId).notifier).removeBookmark(b.id!);
                                    }
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  onPageSelected(b.pageNumber);
                                },
                              );
                            },
                          ),

                    // 3. Notes & Comments Tab
                    Column(
                      children: [
                        // Quick Action Header to Add Note / Comment
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ملاحظاتك وتعليقاتك (${notes.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: settings.primaryButtonColor,
                                  foregroundColor: settings.primaryButtonTextColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.add_comment_rounded, size: 16),
                                label: const Text('إضافة ملاحظة', style: TextStyle(fontSize: 12.5)),
                                onPressed: () => _openNoteEditor(context, ref),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        Expanded(
                          child: notes.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.note_alt_outlined, size: 48, color: Colors.grey),
                                        const Gap(12),
                                        const Text(
                                          'لا توجد ملاحظات أو تعليقات حتى الآن.\nيمكنك إضافة تعليقك الخاص أو تظليل أي نص أثناء القراءة.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                        const Gap(16),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: settings.primaryButtonColor,
                                            foregroundColor: settings.primaryButtonTextColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.add_comment_rounded, size: 18),
                                          label: const Text('إضافة أول ملاحظة'),
                                          onPressed: () => _openNoteEditor(context, ref),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: notes.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final n = notes[index];
                                    final colorInt = int.tryParse(n.colorHex) ?? 0x66FFEB3B;

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: Color(colorInt),
                                        child: Text(
                                          '${n.pageNumber}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      title: n.note.isNotEmpty
                                          ? Text(
                                              n.note,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            )
                                          : Text(
                                              n.selectedText,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                      subtitle: n.note.isNotEmpty && n.selectedText.isNotEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'النص: «${n.selectedText}»',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11.5,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            )
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                                            tooltip: 'تعديل',
                                            onPressed: () => _openNoteEditor(context, ref, existingNote: n),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                            tooltip: 'حذف',
                                            onPressed: () {
                                              if (n.id != null) {
                                                ref.read(notesProvider(bookId).notifier).deleteNote(n.id!);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        onPageSelected(n.pageNumber);
                                      },
                                    );
                                  },
                                ),
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
    ),
  );
}
}
