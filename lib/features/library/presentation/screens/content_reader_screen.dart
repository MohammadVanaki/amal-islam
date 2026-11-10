import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/book_model.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/note_model.dart';
import '../../data/services/book_content_db_service.dart';
import '../../providers/annotations_provider.dart';
import '../../providers/reader_settings_provider.dart';
import '../widgets/bookmark_notes_sheet.dart';
import '../widgets/reading_settings_sheet.dart';

class ContentReaderScreen extends ConsumerStatefulWidget {
  final BookModel book;
  final String dbPath;
  final int initialPage;

  const ContentReaderScreen({
    super.key,
    required this.book,
    required this.dbPath,
    this.initialPage = 1,
  });

  @override
  ConsumerState<ContentReaderScreen> createState() =>
      _ContentReaderScreenState();
}

class _ContentReaderScreenState extends ConsumerState<ContentReaderScreen>
    with TickerProviderStateMixin {
  late final BookContentDbService _contentDbService;
  late final PageController _pageController;
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;

  int _currentPage = 1;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<double> _sliderValueNotifier;
  late final ValueNotifier<bool> _isDraggingSliderNotifier;
  int? _lastJumpedSliderPage;
  DateTime _lastSliderJumpTime = DateTime.now();
  int _totalPages = 1;
  bool _isLoading = true;
  String? _errorMessage;

  // Immersive Fullscreen State
  bool _isImmersive = false;

  // Debounce for saving reading progress
  Timer? _saveProgressDebounce;

  // Track active page loads to prevent duplicate queries
  final Set<int> _loadingPages = {};

  // Highlighted Search Keyword
  String? _highlightedSearchWord;

  // Floating Footnote Overlay State
  String? _activeFootnote;
  Timer? _footnoteDismissTimer;
  late final AnimationController _footnoteAnimController;
  late final Animation<Offset> _footnoteSlideAnim;
  late final Animation<double> _footnoteFadeAnim;
  late final AnimationController _footnoteProgressController;

  // Page Cache
  final Map<int, BookPageContent> _pagesCache = {};

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _currentPageNotifier = ValueNotifier<int>(widget.initialPage);
    _sliderValueNotifier = ValueNotifier<double>(widget.initialPage.toDouble());
    _isDraggingSliderNotifier = ValueNotifier<bool>(false);
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _contentDbService = BookContentDbService(widget.dbPath);

    // Initialize Footnote Overlay Animations
    _footnoteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _footnoteSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _footnoteAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _footnoteFadeAnim = CurvedAnimation(
      parent: _footnoteAnimController,
      curve: Curves.easeOut,
    );
    _footnoteProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _hideFootnoteOverlay();
        }
      });

    _initBook();
  }

  Future<void> _initBook() async {
    try {
      final file = File(widget.dbPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'لم يتم تحميل ملف قاعدة بيانات الكتاب بعد.';
          _isLoading = false;
        });
        return;
      }

      await _contentDbService.initialize();
      setState(() {
        _totalPages = _contentDbService.totalPages > 0
            ? _contentDbService.totalPages
            : 1;
        _isLoading = false;
      });

      // Prefetch generous chunk around the initial page so pages are instantly ready
      await _prefetchChunkAround(_currentPage);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // --- Chunk-based fast prefetching (Batch SQLite Loading) ---
  final Set<int> _loadedChunks = {};

  Future<void> _prefetchChunkAround(int page) async {
    const chunkSize = 15;
    final chunkIndex = page ~/ chunkSize;
    if (_loadedChunks.contains(chunkIndex)) return;
    _loadedChunks.add(chunkIndex);

    final startPage = (chunkIndex * chunkSize - 5).clamp(1, _totalPages);
    final endPage = ((chunkIndex + 1) * chunkSize + 15).clamp(1, _totalPages);

    try {
      final pagesMap =
          await _contentDbService.getPagesRange(startPage, endPage);
      if (pagesMap.isNotEmpty) {
        _pagesCache.addAll(pagesMap);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<BookPageContent?> _loadPage(int page) async {
    if (_pagesCache.containsKey(page)) {
      return _pagesCache[page];
    }
    if (_loadingPages.contains(page)) {
      return null;
    }
    _loadingPages.add(page);
    try {
      final content = await _contentDbService.getPage(page);
      if (content != null) {
        _pagesCache[page] = content;
        if (mounted) setState(() {});
      }
      return content;
    } finally {
      _loadingPages.remove(page);
    }
  }

  void _onHorizontalPageChanged(int index) {
    final page = index + 1;
    _currentPage = page;
    _currentPageNotifier.value = page;
    _sliderValueNotifier.value = page.toDouble();
    _prefetchChunkAround(page);
    _saveReadingProgress(page);
  }

  void _saveReadingProgress(int page) {
    _saveProgressDebounce?.cancel();
    _saveProgressDebounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      ref
          .read(annotationsDbServiceProvider)
          .saveReadingProgress(
            bookId: widget.book.id,
            lastPage: page,
            totalPages: _totalPages,
          );
    });
  }

  void _onItemPositionsChanged() {
    if (_isDraggingSliderNotifier.value) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final visible = positions
        .where((p) => p.itemTrailingEdge > 0.05 && p.itemLeadingEdge < 0.95)
        .toList();
    if (visible.isEmpty) return;

    int? detectedPage;
    for (final pos in visible) {
      if (pos.itemLeadingEdge <= 0.25 && pos.itemTrailingEdge > 0.25) {
        detectedPage = pos.index + 1;
        break;
      }
    }

    if (detectedPage == null) {
      visible.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
      detectedPage = visible.first.index + 1;
    }

    final page = detectedPage.clamp(1, _totalPages);
    if (page != _currentPageNotifier.value) {
      _currentPage = page;
      _currentPageNotifier.value = page;
      _sliderValueNotifier.value = page.toDouble();
      _prefetchChunkAround(page);
      _saveReadingProgress(page);
    }
  }

  void _jumpToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    _currentPage = page;
    _currentPageNotifier.value = page;
    _sliderValueNotifier.value = page.toDouble();
    _prefetchChunkAround(page);
    final settings = ref.read(readerSettingsProvider);
    if (settings.viewMode == ReaderViewMode.horizontalPage) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(page - 1);
      }
    } else {
      if (_itemScrollController.isAttached) {
        _itemScrollController.jumpTo(index: page - 1, alignment: 0);
      }
    }
    _saveReadingProgress(page);
  }

  // --- Toggle Immersive Fullscreen Mode ---
  void _toggleImmersive() {
    setState(() {
      _isImmersive = !_isImmersive;
    });
    if (_isImmersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  // --- Footnote Floating Card Overlay ---
  void _showFootnoteOverlay(String footnoteText) {
    _footnoteDismissTimer?.cancel();
    _footnoteProgressController.stop();
    setState(() {
      _activeFootnote = footnoteText;
    });
    _footnoteAnimController.forward(from: 0.0);
    _footnoteProgressController.forward(from: 0.0);
    HapticFeedback.lightImpact();
  }

  void _hideFootnoteOverlay() {
    _footnoteDismissTimer?.cancel();
    _footnoteProgressController.stop();
    if (_activeFootnote == null) return;
    _footnoteAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _activeFootnote = null;
        });
      }
    });
  }

  // --- Search Keyword Injector for HTML ---
  static String _injectSearchHighlight(String html, String query) {
    if (query.trim().isEmpty) return html;
    final escaped = RegExp.escape(query.trim());
    final pattern = RegExp(
      '(?<!<[^>]*)($escaped)(?![^<]*>)',
      caseSensitive: false,
    );
    return html.replaceAllMapped(pattern, (match) {
      return '<mark class="search-highlight">${match.group(0)}</mark>';
    });
  }

  // --- App SnackBar Helper (Clear of vertical slider) ---
  void _showAppSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    final settings = ref.read(readerSettingsProvider);
    final hasRightSlider =
        settings.viewMode == ReaderViewMode.verticalScroll && !_isImmersive;

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.clearSnackBars();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          hasRightSlider ? 64.0 : 16.0,
          16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: duration,
      ),
    );
  }

  // --- Text Selection Actions ---
  void _handleCopy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    _showAppSnackBar('تم نسخ النص المحدد إلى الحافظة');
  }

  void _handleShare(String text) {
    Share.share(
      '$text\n\n— من كتاب «${widget.book.title}»\nhttps://alam-alislam.com',
      subject: widget.book.title,
    );
  }

  void _handleQuickHighlight(String selectedText, String colorHex) async {
    await ref
        .read(annotationsDbServiceProvider)
        .addNote(
          NoteModel(
            bookId: widget.book.id,
            pageNumber: _currentPageNotifier.value,
            selectedText: selectedText,
            note: '',
            colorHex: colorHex,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _showAppSnackBar('تم تظليل النص وحفظه بنجاح');
  }

  void _showAddNoteDialog(String selectedText, {int? pageNumber}) {
    final settings = ref.read(readerSettingsProvider);
    final targetPage = pageNumber ?? _currentPageNotifier.value;
    final noteController = TextEditingController();
    String selectedColor = '0x66FFEB3B';
    final hasQuote = selectedText.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppColors.accent,
                size: 24,
              ),
              const Gap(8),
              Text(
                hasQuote
                    ? 'إضافة ملاحظة وتمييز'
                    : 'إضافة تعليق وملاحظة (صفحة $targetPage)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasQuote) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '«$selectedText»',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const Gap(14),
                ],
                const Text(
                  'لون التمييز:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _colorOption(
                      color: AppColors.highlightYellow,
                      hex: '0x66FFEB3B',
                      selected: selectedColor == '0x66FFEB3B',
                      onSelect: () =>
                          setDialogState(() => selectedColor = '0x66FFEB3B'),
                    ),
                    _colorOption(
                      color: AppColors.highlightGreen,
                      hex: '0x664CAF50',
                      selected: selectedColor == '0x664CAF50',
                      onSelect: () =>
                          setDialogState(() => selectedColor = '0x664CAF50'),
                    ),
                    _colorOption(
                      color: AppColors.highlightBlue,
                      hex: '0x662196F3',
                      selected: selectedColor == '0x662196F3',
                      onSelect: () =>
                          setDialogState(() => selectedColor = '0x662196F3'),
                    ),
                    _colorOption(
                      color: AppColors.highlightPink,
                      hex: '0x66E91E63',
                      selected: selectedColor == '0x66E91E63',
                      onSelect: () =>
                          setDialogState(() => selectedColor = '0x66E91E63'),
                    ),
                  ],
                ),
                const Gap(14),
                TextField(
                  controller: noteController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'نص الملاحظة أو التعليق',
                    hintText: hasQuote
                        ? 'اكتب ملاحظتك على هذا النص...'
                        : 'اكتب فائدتك أو تعليقك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  maxLines: 3,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final text = noteController.text.trim();
                if (text.isEmpty && !hasQuote) return;

                Navigator.pop(ctx);
                await ref
                    .read(notesProvider(widget.book.id).notifier)
                    .addNote(
                      pageNumber: targetPage,
                      selectedText: hasQuote
                          ? selectedText
                          : 'ملاحظة على صفحة $targetPage',
                      note: text,
                      colorHex: selectedColor,
                    );
                if (!mounted) return;
                HapticFeedback.lightImpact();
                _showAppSnackBar('تم حفظ الملاحظة بنجاح للصفحة $targetPage');
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePageBookmark(int pageNum, BookPageContent? content) async {
    final added = await ref
        .read(bookmarksProvider(widget.book.id).notifier)
        .toggleBookmark(
          pageNumber: pageNum,
          title: content?.title ?? 'صفحة $pageNum',
          snippet: content != null && content.text.isNotEmpty
              ? (content.text.length > 60
                    ? '${content.text.substring(0, 60)}...'
                    : content.text)
              : null,
        );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _showAppSnackBar(
      added
          ? 'تمت إضافة إشارة مرجعية للصفحة $pageNum'
          : 'تمت إزالة الإشارة المرجعية من الصفحة $pageNum',
      duration: const Duration(seconds: 1),
    );
  }

  void _showPageNotesSheet(int pageNum, List<NoteModel> pageNotes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final settings = ref.watch(readerSettingsProvider);
          final allNotes = ref.watch(notesProvider(widget.book.id));
          final currentNotes = allNotes
              .where((n) => n.pageNumber == pageNum)
              .toList();

          return Material(
            color: settings.backgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.72,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Gap(12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.note_alt_rounded,
                              color: settings.primaryButtonColor,
                              size: 22,
                            ),
                            const Gap(8),
                            Text(
                              'ملاحظات الصفحة $pageNum (${currentNotes.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: settings.textColor,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: settings.primaryButtonColor,
                            foregroundColor: settings.primaryButtonTextColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(
                            'إضافة جديدة',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddNoteDialog('', pageNumber: pageNum);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: currentNotes.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد ملاحظات على هذه الصفحة',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: currentNotes.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, index) {
                              final note = currentNotes[index];
                              final colorInt =
                                  int.tryParse(note.colorHex) ?? 0x66FFEB3B;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Color(colorInt),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  note.note,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle:
                                    note.selectedText.isNotEmpty &&
                                        !note.selectedText.startsWith(
                                          'ملاحظة على صفحة',
                                        )
                                    ? Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(
                                          '«${note.selectedText}»',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    if (note.id != null) {
                                      await ref
                                          .read(
                                            notesProvider(widget.book.id)
                                                .notifier,
                                          )
                                          .deleteNote(note.id!);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildPageActionButtons({
    required int pageNum,
    required BookPageContent? content,
    required ReaderSettingsState settings,
    required bool isBookmarked,
    required List<NoteModel> pageNotes,
  }) {
    const activeColor = Color(0xFFE53935); // Red color for active bookmark/comment

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Comment / Note Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (pageNotes.isNotEmpty) {
                _showPageNotesSheet(pageNum, pageNotes);
              } else {
                _showAddNoteDialog('', pageNumber: pageNum);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Badge(
                isLabelVisible: pageNotes.isNotEmpty,
                label: Text(
                  '${pageNotes.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: activeColor,
                child: Icon(
                  pageNotes.isNotEmpty
                      ? Icons.comment_rounded
                      : Icons.add_comment_outlined,
                  size: 19,
                  color: pageNotes.isNotEmpty
                      ? activeColor
                      : settings.textColor.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
        const Gap(4),
        // 2. Bookmark Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _togglePageBookmark(pageNum, content),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                size: 20,
                color: isBookmarked
                    ? activeColor
                    : settings.textColor.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _colorOption({
    required Color color,
    required String hex,
    required bool selected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      child: Container(
        width: 34,
        height: 34,
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

  // --- Snippet Builder with Highlighted Query ---
  Widget _buildHighlightedSnippet(String snippet, String query) {
    if (query.isEmpty) {
      return Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    final lowerSnippet = snippet.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerSnippet.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: snippet.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: snippet.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: snippet.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFD54F),
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: spans,
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    List<BookSearchResult> searchResults = [];
    bool isSearching = false;
    String currentQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(14),
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث عن كلمة أو عبارة في الكتاب...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded),
                    onPressed: () async {
                      final query = searchController.text.trim();
                      if (query.isNotEmpty) {
                        setSheetState(() {
                          isSearching = true;
                          currentQuery = query;
                        });
                        final results = await _contentDbService.search(query);
                        setSheetState(() {
                          searchResults = results;
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                onSubmitted: (query) async {
                  final q = query.trim();
                  if (q.isNotEmpty) {
                    setSheetState(() {
                      isSearching = true;
                      currentQuery = q;
                    });
                    final results = await _contentDbService.search(q);
                    setSheetState(() {
                      searchResults = results;
                      isSearching = false;
                    });
                  }
                },
              ),
              const Gap(12),
              if (isSearching)
                const LinearProgressIndicator(color: AppColors.accent)
              else
                Expanded(
                  child: searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد نتائج بحث',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: searchResults.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final res = searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.accent.withValues(
                                  alpha: 0.18,
                                ),
                                child: Text(
                                  '${res.pageNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              title: _buildHighlightedSnippet(
                                res.snippet,
                                currentQuery,
                              ),
                              onTap: () {
                                final query = searchController.text.trim();
                                Navigator.pop(ctx);
                                setState(() {
                                  _highlightedSearchWord = query.isNotEmpty
                                      ? query
                                      : null;
                                });
                                _jumpToPage(res.pageNumber);
                              },
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    _saveProgressDebounce?.cancel();
    _currentPageNotifier.dispose();
    _sliderValueNotifier.dispose();
    _isDraggingSliderNotifier.dispose();
    _footnoteDismissTimer?.cancel();
    _footnoteProgressController.dispose();
    _footnoteAnimController.dispose();
    _pageController.dispose();
    _contentDbService.close();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);
    final currentPalette = ref.watch(appPaletteProvider);
    final bookmarks = ref.watch(bookmarksProvider(widget.book.id));
    final notes = ref.watch(notesProvider(widget.book.id));

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    final double topBarBaseHeight = isLandscape ? 48.0 : 56.0;
    final double topBarTotalHeight = mediaQuery.padding.top + topBarBaseHeight;

    final double bottomBarBaseHeight = isLandscape ? 48.0 : 56.0;
    final double bottomBarTotalHeight =
        mediaQuery.padding.bottom + bottomBarBaseHeight;

    final double activeTopPadding = _isImmersive
        ? (mediaQuery.padding.top + 12.0)
        : (topBarTotalHeight + 8.0);

    final double activeBottomPadding = _isImmersive
        ? (mediaQuery.padding.bottom + 12.0)
        : (settings.viewMode == ReaderViewMode.horizontalPage
            ? (bottomBarTotalHeight + 8.0)
            : (mediaQuery.padding.bottom + 16.0));

    final isNight = settings.themeMode == ReaderThemeMode.night;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isNight ? Brightness.light : Brightness.dark,
        statusBarBrightness: isNight ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isNight ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: settings.backgroundColor,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.accent),
                  const Gap(16),
                  Text(
                    'جاري فتح صفحات الكتاب...',
                    style: TextStyle(
                      color: settings.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const Gap(16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: settings.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('رجوع'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // Main Reading View (Gesture for toggling immersive mode)
                GestureDetector(
                  onTap: _toggleImmersive,
                  behavior: HitTestBehavior.translucent,
                  child: settings.viewMode == ReaderViewMode.horizontalPage
                      ? _buildHorizontalPageView(
                          settings: settings,
                          bookmarks: bookmarks,
                          notes: notes,
                          topPadding: activeTopPadding,
                          bottomPadding: activeBottomPadding,
                        )
                      : _buildVerticalScrollView(
                          settings: settings,
                          bookmarks: bookmarks,
                          notes: notes,
                          topPadding: activeTopPadding,
                          bottomPadding: activeBottomPadding,
                        ),
                ),

                // Top Animated AppBar
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  top: _isImmersive ? -topBarTotalHeight : 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(
                    settings: settings,
                    topBarTotalHeight: topBarTotalHeight,
                  ),
                ),

                // Search Highlight Floating Indicator
                if (_highlightedSearchWord != null &&
                    _highlightedSearchWord!.isNotEmpty)
                  Positioned(
                    top: _isImmersive ? 14 : (topBarTotalHeight + 6),
                    left: 20,
                    right: (settings.viewMode ==
                                ReaderViewMode.verticalScroll &&
                            !_isImmersive)
                        ? 60.0
                        : 20.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const Gap(8),
                              Text(
                                'تم تمييز كلمة: «$_highlightedSearchWord»',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () =>
                                setState(() => _highlightedSearchWord = null),
                            child: const Padding(
                              padding: EdgeInsets.all(3.0),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Animated Controls Bar (Horizontal Mode)
                if (settings.viewMode == ReaderViewMode.horizontalPage)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    bottom: _isImmersive ? -bottomBarTotalHeight : 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(
                      settings: settings,
                      currentPalette: currentPalette,
                      bottomBarTotalHeight: bottomBarTotalHeight,
                    ),
                  ),

                // Side Animated Vertical Slider (Vertical Mode)
                if (settings.viewMode == ReaderViewMode.verticalScroll)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    right: _isImmersive ? -70.0 : 10.0,
                    top: topBarTotalHeight + 14.0,
                    bottom: mediaQuery.padding.bottom + 20.0,
                    child: _buildVerticalSlider(settings, currentPalette),
                  ),

                // Bottom Floating Footnote Card Overlay (Rendered above slider with clearance)
                if (_activeFootnote != null)
                  Positioned(
                    bottom: _isImmersive
                        ? (mediaQuery.padding.bottom + 16.0)
                        : (settings.viewMode == ReaderViewMode.horizontalPage
                            ? (bottomBarTotalHeight + 12.0)
                            : (mediaQuery.padding.bottom + 20.0)),
                    left: 16,
                    right: (settings.viewMode ==
                                ReaderViewMode.verticalScroll &&
                            !_isImmersive)
                        ? 60.0
                        : 16.0,
                    child: SlideTransition(
                      position: _footnoteSlideAnim,
                      child: FadeTransition(
                        opacity: _footnoteFadeAnim,
                        child: _buildFloatingFootnoteCard(settings),
                      ),
                    ),
                  ),
              ],
            ),
      ),
    );
  }

  // --- 1. Horizontal Page Flip (PageView RTL) ---
  Widget _buildHorizontalPageView({
    required ReaderSettingsState settings,
    required List<BookmarkModel> bookmarks,
    required List<NoteModel> notes,
    required double topPadding,
    required double bottomPadding,
  }) {
    return PageView.builder(
      controller: _pageController,
      itemCount: _totalPages,
      onPageChanged: _onHorizontalPageChanged,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        final content = _pagesCache[pageNum];
        final isBookmarked = bookmarks.any((b) => b.pageNumber == pageNum);
        final pageNotes = notes.where((n) => n.pageNumber == pageNum).toList();

        if (content == null) {
          _loadPage(pageNum);
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }

        return _buildPageContainer(
          content: content,
          settings: settings,
          pageNum: pageNum,
          topPadding: topPadding,
          bottomPadding: bottomPadding,
          isBookmarked: isBookmarked,
          pageNotes: pageNotes,
        );
      },
    );
  }

  // --- 2. Vertical Continuous Scroll ---
  Widget _buildVerticalScrollView({
    required ReaderSettingsState settings,
    required List<BookmarkModel> bookmarks,
    required List<NoteModel> notes,
    required double topPadding,
    required double bottomPadding,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final double defaultSidePadding = isLandscape ? 28.0 : 20.0;
    final double leftPadding = mediaQuery.padding.left + defaultSidePadding;
    // When immersive (fullscreen), slider is hidden, so text expands to take the full width.
    // When not immersive, leave clearance on right for vertical slider (10 + 38 + 16 = 64).
    final double rightPadding = _isImmersive
        ? (mediaQuery.padding.right + defaultSidePadding)
        : (mediaQuery.padding.right + (isLandscape ? 72.0 : 64.0));

    final initialIndex = (widget.initialPage - 1).clamp(
      0,
      _totalPages > 0 ? _totalPages - 1 : 0,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.fromLTRB(
        leftPadding,
        topPadding,
        rightPadding,
        bottomPadding,
      ),
      child: ScrollablePositionedList.builder(
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        itemCount: _totalPages,
        initialScrollIndex: initialIndex,
        minCacheExtent: 2400.0,
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final isBookmarked =
              bookmarks.any((b) => b.pageNumber == pageNum);
          final pageNotes =
              notes.where((n) => n.pageNumber == pageNum).toList();

          return _VerticalPageItem(
            key: ValueKey(pageNum),
            pageNum: pageNum,
            totalPages: _totalPages,
            contentDbService: _contentDbService,
            pagesCache: _pagesCache,
            loadingPages: _loadingPages,
            settings: settings,
            isBookmarked: isBookmarked,
            pageNotes: pageNotes,
            contentBuilder: _buildPageContentBody,
            selectionContextMenuBuilder: _buildSelectionContextMenu,
            onToggleBookmark: _togglePageBookmark,
            onShowNotes: _showPageNotesSheet,
            onAddNote: _showAddNoteDialog,
            onPrefetch: _prefetchChunkAround,
          );
        },
      ),
    );
  }

  // --- Page Content Container ---
  Widget _buildPageContainer({
    required BookPageContent content,
    required ReaderSettingsState settings,
    required int pageNum,
    required double topPadding,
    required double bottomPadding,
    required bool isBookmarked,
    required List<NoteModel> pageNotes,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final horizontalPadding = mediaQuery.orientation == Orientation.landscape
        ? 32.0
        : 20.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding + mediaQuery.padding.left,
        topPadding,
        horizontalPadding + mediaQuery.padding.right,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page Header (Book Title, Page Action Buttons & Page Number)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    content.title ?? widget.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: settings.textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Gap(8),
                _buildPageActionButtons(
                  pageNum: pageNum,
                  content: content,
                  settings: settings,
                  isBookmarked: isBookmarked,
                  pageNotes: pageNotes,
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: settings.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: settings.hrColor.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    'صفحة $pageNum',
                    style: TextStyle(
                      color: settings.textColor.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: settings.hrColor.withValues(alpha: 0.4)),
          const Gap(8),

          // Scrollable Page Content
          Expanded(
            child: SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) =>
                  _buildSelectionContextMenu(selectableRegionState),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildPageContentBody(content, settings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionContextMenu(
    SelectableRegionState selectableRegionState,
  ) {
    final selectedText = selectableRegionState.textEditingValue.selection
        .textInside(selectableRegionState.textEditingValue.text);

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectableRegionState.contextMenuAnchors,
      buttonItems: [
        // 1. Copy
        ContextMenuButtonItem(
          label: 'نسخ',
          onPressed: () {
            selectableRegionState.hideToolbar();
            if (selectedText.isNotEmpty) {
              _handleCopy(selectedText);
            }
          },
        ),

        // 2. Share
        ContextMenuButtonItem(
          label: 'مشاركة',
          onPressed: () {
            selectableRegionState.hideToolbar();
            if (selectedText.isNotEmpty) {
              _handleShare(selectedText);
            }
          },
        ),

        // 3. Highlight
        ContextMenuButtonItem(
          label: 'تظليل',
          onPressed: () {
            selectableRegionState.hideToolbar();
            if (selectedText.isNotEmpty) {
              _handleQuickHighlight(selectedText, '0x66FFEB3B');
            }
          },
        ),

        // 4. Note
        ContextMenuButtonItem(
          label: 'ملاحظة',
          onPressed: () {
            selectableRegionState.hideToolbar();
            if (selectedText.isNotEmpty) {
              _showAddNoteDialog(selectedText);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPageContentBody(
    BookPageContent content,
    ReaderSettingsState settings,
  ) {
    // Inject search highlight into HTML if a keyword is searched
    final rawHtml =
        (_highlightedSearchWord != null &&
            _highlightedSearchWord!.trim().isNotEmpty)
        ? _injectSearchHighlight(content.html, _highlightedSearchWord!)
        : content.html;

    // Wrap in justified container to ensure full-page justify alignment
    final htmlToRender =
        '<div class="book-body" style="text-align: justify;">$rawHtml</div>';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: HtmlWidget(
        htmlToRender,
        textStyle: TextStyle(
          color: settings.textColor,
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          fontFamily: settings.fontFamily.fontFamilyName,
        ),
          customStylesBuilder: (element) {
            final classes = element.classes;

            if (classes.contains('search-highlight') ||
                element.localName == 'mark') {
              return {
                'background-color': '#FFD54F',
                'color': '#000000',
                'font-weight': 'bold',
                'padding': '1px 4px',
                'border-radius': '4px',
              };
            }

            if (classes.contains('centertxt')) {
              return {
                'text-align': 'center',
                'font-weight': 'bold',
                'margin-top': '8px',
                'margin-bottom': '8px',
              };
            }

            if (classes.contains('tit1') || element.localName == 'h1') {
              return {
                'color': settings.headingColorHex,
                'text-align': 'center',
                'font-weight': 'bold',
                'font-size': '1.3em',
                'margin-top': '18px',
                'margin-bottom': '14px',
              };
            }

            if (element.localName == 'h2' || element.localName == 'h3') {
              return {
                'color': settings.headingColorHex,
                'text-align': 'center',
                'font-weight': 'bold',
                'font-size': '1.15em',
                'margin-top': '14px',
                'margin-bottom': '10px',
              };
            }

            if (classes.contains('quran')) {
              return {'color': settings.quranColorHex, 'font-weight': 'bold'};
            }

            if (classes.contains('fnote')) {
              return {
                'color': settings.footnoteColorHex,
                'font-size': '0.86em',
                'line-height': '1.5',
                'text-align': 'justify',
              };
            }

            if (classes.contains('fn')) {
              return {
                'color': settings.headingColorHex,
                'font-weight': 'bold',
                'font-size': '0.85em',
              };
            }

            if (classes.contains('txtleft')) {
              return {
                'text-align': 'left',
                'display': 'block',
                'margin-top': '12px',
              };
            }

            if (element.localName == 'p') {
              return {'text-align': 'justify', 'margin-bottom': '8px'};
            }

            if (element.localName == 'div' ||
                element.localName == 'body' ||
                element.localName == 'section' ||
                element.localName == 'article' ||
                classes.contains('book-body')) {
              return {'text-align': 'justify'};
            }

            return null;
          },
          customWidgetBuilder: (element) {
            // Footnote Separator Line between main text and footnotes (نصف صفحه و کمرنگ‌تر)
            if (element.localName == 'hr' ||
                element.classes.contains('fnote_hr')) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: 0.48,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 12),
                    height: 1.0,
                    decoration: BoxDecoration(
                      color: settings.textColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              );
            }

            // Interactive Footnote Marker (Wrapped in InlineCustomWidget so it stays inline with text)
            if (element.classes.contains('fn') &&
                element.attributes.containsKey('title')) {
              final tooltip = element.attributes['title'];
              if (tooltip != null &&
                  tooltip.trim().isNotEmpty &&
                  element.text.trim().isNotEmpty) {
                return InlineCustomWidget(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => _showFootnoteOverlay(tooltip.trim()),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: settings.headingColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        element.text,
                        style: TextStyle(
                          color: settings.headingColor,
                          fontFamily: settings.fontFamily.fontFamilyName,
                          fontSize: (settings.fontSize * 0.82).clamp(12.0, 24.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
            return null;
          },
        ),
      );
  }

  // --- Floating Footnote Overlay Card ---
  Widget _buildFloatingFootnoteCard(ReaderSettingsState settings) {
    return Dismissible(
      key: const ValueKey('floating_footnote'),
      direction: DismissDirection.down,
      onDismissed: (_) => _hideFootnoteOverlay(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: settings.themeMode == ReaderThemeMode.night
              ? const Color(0xFF1D2624)
              : (settings.themeMode == ReaderThemeMode.sepia
                    ? const Color(0xFFF4E8D3)
                    : (settings.themeMode == ReaderThemeMode.softGray
                          ? const Color(0xFFDCE0E3)
                          : Colors.white)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: settings.headingColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: settings.headingColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: settings.headingColor,
                    size: 18,
                  ),
                ),
                const Gap(8),
                const Text(
                  'الهامش',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _hideFootnoteOverlay,
                ),
              ],
            ),
            const Divider(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  _activeFootnote!,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: settings.textColor,
                  ),
                ),
              ),
            ),
            const Gap(10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedBuilder(
                animation: _footnoteProgressController,
                builder: (context, _) => LinearProgressIndicator(
                  value: 1.0 - _footnoteProgressController.value,
                  minHeight: 2.5,
                  backgroundColor:
                      settings.primaryButtonColor.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    settings.primaryButtonColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top Animated AppBar ---
  Widget _buildTopBar({
    required ReaderSettingsState settings,
    required double topBarTotalHeight,
  }) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;

    return Container(
      height: topBarTotalHeight,
      padding: EdgeInsets.only(top: statusBarHeight, left: 8, right: 8),
      decoration: BoxDecoration(
        color: settings.appBarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Right Side: Back & Table of Contents / Index
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: settings.appBarTextColor,
            ),
            tooltip: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: Icon(
              Icons.menu_book_rounded,
              color: settings.appBarTextColor,
            ),
            tooltip: 'الفهرس والملاحظات',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => BookmarkNotesSheet(
                  bookId: widget.book.id,
                  chapters: _contentDbService.chapters,
                  currentPage: _currentPage,
                  onPageSelected: (page) => _jumpToPage(page),
                ),
              );
            },
          ),

          // Center: Book Title
          Expanded(
            child: Text(
              widget.book.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: settings.appBarTextColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Left Side: Search & Reading Settings
          IconButton(
            icon: Icon(Icons.search_rounded, color: settings.appBarTextColor),
            tooltip: 'بحث في الكتاب',
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: Icon(Icons.settings_rounded, color: settings.appBarTextColor),
            tooltip: 'خيارات القراءة',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const ReadingSettingsSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Bottom Animated Controls Bar ---
  Widget _buildBottomBar({
    required ReaderSettingsState settings,
    required AppPalette currentPalette,
    required double bottomBarTotalHeight,
  }) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      height: bottomBarTotalHeight,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      decoration: BoxDecoration(
        color: settings.appBarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _currentPageNotifier,
        builder: (context, currentPage, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$currentPage',
                style: TextStyle(
                  color: settings.appBarTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: currentPalette.color,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    thumbColor: currentPalette.color,
                    trackHeight: 3.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.5,
                    ),
                    showValueIndicator: ShowValueIndicator.always,
                    valueIndicatorColor: currentPalette.color,
                    valueIndicatorTextStyle: GoogleFonts.ibmPlexSansArabic(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  child: Slider(
                    value: currentPage.toDouble().clamp(
                      1.0,
                      _totalPages.toDouble(),
                    ),
                    min: 1.0,
                    max: _totalPages > 0 ? _totalPages.toDouble() : 1.0,
                    label: 'صفحة $currentPage',
                    onChanged: (val) {
                      _jumpToPage(val.toInt());
                    },
                  ),
                ),
              ),
              Text(
                '$_totalPages',
                style: TextStyle(
                  color: settings.appBarTextColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Side Animated Vertical Slider (For Vertical Scroll Mode) ---
  Widget _buildVerticalSlider(ReaderSettingsState settings, AppPalette currentPalette) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;
        const double topOffset = 38.0;
        const double bottomOffset = 38.0;
        final double trackHeight =
            (totalHeight - topOffset - bottomOffset).clamp(50.0, double.infinity);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. The Rail Container (Static layout, does not rebuild during slide)
            GestureDetector(
              onTap: () {}, // Prevent tap from toggling immersive mode
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: totalHeight,
                decoration: BoxDecoration(
                  color: settings.appBarColor.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: settings.hrColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(1, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Current Page badge indicator at the top
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: currentPalette.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ValueListenableBuilder<double>(
                          valueListenable: _sliderValueNotifier,
                          builder: (context, val, _) {
                            final pageNum = val.toInt().clamp(1, _totalPages);
                            return Text(
                              '$pageNum',
                              style: TextStyle(
                                color: currentPalette.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Vertical Slider rotated 90 deg clockwise in LTR
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: currentPalette.color,
                              inactiveTrackColor:
                                  Colors.grey.withValues(alpha: 0.25),
                              thumbColor: currentPalette.color,
                              trackHeight: 3.5,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 13,
                              ),
                            ),
                            child: ValueListenableBuilder<double>(
                              valueListenable: _sliderValueNotifier,
                              builder: (context, sliderVal, _) {
                                return Slider(
                                  value: sliderVal.clamp(
                                    1.0,
                                    _totalPages > 0 ? _totalPages.toDouble() : 1.0,
                                  ),
                                  min: 1.0,
                                  max: _totalPages > 0
                                      ? _totalPages.toDouble()
                                      : 1.0,
                                  onChangeStart: (val) {
                                    _isDraggingSliderNotifier.value = true;
                                  },
                                  onChanged: (val) {
                                    _sliderValueNotifier.value = val;
                                    final newPage =
                                        val.toInt().clamp(1, _totalPages);
                                    final now = DateTime.now();
                                    if (newPage != _lastJumpedSliderPage &&
                                        now.difference(_lastSliderJumpTime).inMilliseconds >= 70) {
                                      _lastSliderJumpTime = now;
                                      _lastJumpedSliderPage = newPage;
                                      _currentPage = newPage;
                                      _currentPageNotifier.value = newPage;
                                      if (_itemScrollController.isAttached) {
                                        _itemScrollController.jumpTo(
                                          index: newPage - 1,
                                          alignment: 0,
                                        );
                                      }
                                      _prefetchChunkAround(newPage);
                                    }
                                  },
                                  onChangeEnd: (val) {
                                    _isDraggingSliderNotifier.value = false;
                                    final finalPage =
                                        val.toInt().clamp(1, _totalPages);
                                    _currentPage = finalPage;
                                    _currentPageNotifier.value = finalPage;
                                    _sliderValueNotifier.value = finalPage.toDouble();
                                    _lastJumpedSliderPage = finalPage;
                                    if (_itemScrollController.isAttached) {
                                      _itemScrollController.jumpTo(
                                        index: finalPage - 1,
                                        alignment: 0,
                                      );
                                    }
                                    _prefetchChunkAround(finalPage);
                                    _saveReadingProgress(finalPage);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Total Pages indicator at bottom
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 2),
                      child: Text(
                        '$_totalPages',
                        style: TextStyle(
                          color: settings.appBarTextColor.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Dynamic Tooltip Bubble (Fast 120fps direct Positioned with zero animation lag)
            ValueListenableBuilder<bool>(
              valueListenable: _isDraggingSliderNotifier,
              builder: (context, isDragging, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: _sliderValueNotifier,
                  builder: (context, sliderVal, _) {
                    final int displayPage = sliderVal.toInt().clamp(1, _totalPages);
                    final double progress = _totalPages > 1
                        ? ((sliderVal - 1.0) / (_totalPages - 1)).clamp(0.0, 1.0)
                        : 0.0;
                    final double tooltipY = (topOffset + progress * trackHeight - 16)
                        .clamp(8.0, totalHeight - 40.0);

                    return Positioned(
                      right: 46,
                      top: tooltipY,
                      child: AnimatedOpacity(
                        opacity: isDragging ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 140),
                        child: IgnorePointer(
                          ignoring: true,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: currentPalette.color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: currentPalette.accent.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    blurRadius: 8,
                                    offset: const Offset(1, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.menu_book_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const Gap(6),
                                  Text(
                                    'صفحة $displayPage',
                                    style: GoogleFonts.ibmPlexSansArabic(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _VerticalPageItem extends StatefulWidget {
  final int pageNum;
  final int totalPages;
  final BookContentDbService contentDbService;
  final Map<int, BookPageContent> pagesCache;
  final Set<int> loadingPages;
  final ReaderSettingsState settings;
  final bool isBookmarked;
  final List<NoteModel> pageNotes;
  final Widget Function(BookPageContent content, ReaderSettingsState settings)
      contentBuilder;
  final Widget Function(SelectableRegionState selectableRegionState)?
      selectionContextMenuBuilder;
  final void Function(int pageNum, BookPageContent? content) onToggleBookmark;
  final void Function(int pageNum, List<NoteModel> pageNotes) onShowNotes;
  final void Function(String text, {int? pageNumber}) onAddNote;
  final Future<void> Function(int page)? onPrefetch;

  const _VerticalPageItem({
    super.key,
    required this.pageNum,
    required this.totalPages,
    required this.contentDbService,
    required this.pagesCache,
    required this.loadingPages,
    required this.settings,
    required this.isBookmarked,
    required this.pageNotes,
    required this.contentBuilder,
    this.selectionContextMenuBuilder,
    required this.onToggleBookmark,
    required this.onShowNotes,
    required this.onAddNote,
    this.onPrefetch,
  });

  @override
  State<_VerticalPageItem> createState() => _VerticalPageItemState();
}

class _VerticalPageItemState extends State<_VerticalPageItem> {
  BookPageContent? _content;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didUpdateWidget(covariant _VerticalPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNum != widget.pageNum) {
      _loadContent();
    }
  }

  void _loadContent() {
    if (widget.pagesCache.containsKey(widget.pageNum)) {
      _content = widget.pagesCache[widget.pageNum];
      return;
    }

    if (widget.loadingPages.contains(widget.pageNum)) {
      return;
    }

    widget.loadingPages.add(widget.pageNum);

    // Trigger batch chunk prefetch around this page
    widget.onPrefetch?.call(widget.pageNum);

    widget.contentDbService.getPage(widget.pageNum).then((data) {
      if (!mounted) return;
      if (data != null) {
        widget.pagesCache[widget.pageNum] = data;
        setState(() {
          _content = data;
        });
      }
    }).catchError((_) {}).whenComplete(() {
      widget.loadingPages.remove(widget.pageNum);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_content == null && widget.pagesCache.containsKey(widget.pageNum)) {
      _content = widget.pagesCache[widget.pageNum];
    }

    if (_content == null) {
      return SizedBox(
        height: 320,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
              ),
              const Gap(8),
              Text(
                'صفحة ${widget.pageNum}',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.settings.textColor.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSeparator(),
          if (widget.selectionContextMenuBuilder != null)
            SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) =>
                  widget.selectionContextMenuBuilder!(selectableRegionState),
              child: widget.contentBuilder(_content!, widget.settings),
            )
          else
            widget.contentBuilder(_content!, widget.settings),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: widget.settings.hrColor.withValues(alpha: 0.5),
              thickness: 0.8,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: widget.settings.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (widget.isBookmarked || widget.pageNotes.isNotEmpty)
                    ? const Color(0xFFE53935)
                    : widget.settings.hrColor.withValues(alpha: 0.8),
                width:
                    (widget.isBookmarked || widget.pageNotes.isNotEmpty) ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'صفحة ${widget.pageNum}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: widget.settings.textColor.withValues(alpha: 0.8),
                  ),
                ),
                const Gap(8),
                Container(
                  width: 1,
                  height: 14,
                  color: widget.settings.hrColor.withValues(alpha: 0.7),
                ),
                const Gap(6),
                _buildActionButtons(),
              ],
            ),
          ),
          Expanded(
            child: Divider(
              color: widget.settings.hrColor.withValues(alpha: 0.5),
              thickness: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    const activeColor = Color(0xFFE53935);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Comment / Note Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (widget.pageNotes.isNotEmpty) {
                widget.onShowNotes(widget.pageNum, widget.pageNotes);
              } else {
                widget.onAddNote('', pageNumber: widget.pageNum);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Badge(
                isLabelVisible: widget.pageNotes.isNotEmpty,
                label: Text(
                  '${widget.pageNotes.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: activeColor,
                child: Icon(
                  widget.pageNotes.isNotEmpty
                      ? Icons.comment_rounded
                      : Icons.add_comment_outlined,
                  size: 19,
                  color: widget.pageNotes.isNotEmpty
                      ? activeColor
                      : widget.settings.textColor.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
        const Gap(4),
        // 2. Bookmark Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onToggleBookmark(widget.pageNum, _content),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              child: Icon(
                widget.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                size: 20,
                color: widget.isBookmarked
                    ? activeColor
                    : widget.settings.textColor.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
