import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../data/models/book_model.dart';
import '../../providers/annotations_provider.dart';
import '../widgets/bookmark_notes_sheet.dart';

class PdfReaderScreen extends ConsumerStatefulWidget {
  final BookModel book;
  final String filePath;
  final int initialPage;

  const PdfReaderScreen({
    super.key,
    required this.book,
    required this.filePath,
    this.initialPage = 1,
  });

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  late final PdfViewerController _pdfController;
  late final PdfTextSearchResult _searchResult;
  late final File _pdfFile;
  late final ValueNotifier<int> _currentPageNotifier;
  late final ValueNotifier<int> _totalPagesNotifier;
  late final ValueNotifier<double> _sliderValNotifier;
  bool _isDraggingSlider = false;
  int _lastJumpedPage = 1;
  DateTime _lastJumpTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _saveProgressDebounce;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
    _pdfFile = File(widget.filePath);
    _currentPageNotifier = ValueNotifier<int>(widget.initialPage);
    _totalPagesNotifier = ValueNotifier<int>(1);
    _sliderValNotifier = ValueNotifier<double>(widget.initialPage.toDouble());
    _lastJumpedPage = widget.initialPage;
  }

  @override
  void dispose() {
    _saveProgressDebounce?.cancel();
    _saveProgress(_currentPageNotifier.value);
    _currentPageNotifier.dispose();
    _totalPagesNotifier.dispose();
    _sliderValNotifier.dispose();
    _searchController.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  void _scheduleSaveProgress(int page) {
    _saveProgressDebounce?.cancel();
    _saveProgressDebounce = Timer(const Duration(milliseconds: 600), () {
      _saveProgress(page);
    });
  }

  void _saveProgress(int page) {
    final total = _totalPagesNotifier.value > 0 ? _totalPagesNotifier.value : 1;
    ref.read(annotationsDbServiceProvider).saveReadingProgress(
          bookId: widget.book.id,
          lastPage: page,
          totalPages: total,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarksProvider(widget.book.id));
    final currentPalette = ref.watch(appPaletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'البحث داخل الكتاب...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    _searchResult.clear();
                    _pdfController.searchText(query);
                  }
                },
              )
            : Text(
                widget.book.title,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 16, fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.navigate_before_rounded),
              onPressed: () => _searchResult.previousInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next_rounded),
              onPressed: () => _searchResult.nextInstance(),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResult.clear();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'بحث',
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, _) {
                final isBookmarked = bookmarks.any((b) => b.pageNumber == currentPage);
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked ? currentPalette.accent : Colors.white,
                  ),
                  tooltip: 'إشارة مرجعية',
                  onPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    final added = await ref.read(bookmarksProvider(widget.book.id).notifier).toggleBookmark(
                          pageNumber: currentPage,
                          title: 'صفحة $currentPage',
                        );
                    if (!mounted) return;
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? 'تمت إضافة إشارة مرجعية'
                              : 'تمت إزالة الإشارة المرجعية',
                          style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.bold),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.list_alt_rounded),
              tooltip: 'الإشارات المرجعية والملاحظات',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => BookmarkNotesSheet(
                    bookId: widget.book.id,
                    onPageSelected: (page) {
                      _currentPageNotifier.value = page;
                      _sliderValNotifier.value = page.toDouble();
                      _pdfController.jumpToPage(page);
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            _pdfFile,
            controller: _pdfController,
            initialPageNumber: widget.initialPage,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            canShowPaginationDialog: false,
            canShowPageLoadingIndicator: true,
            enableDoubleTapZooming: true,
            enableDocumentLinkAnnotation: true,
            interactionMode: PdfInteractionMode.pan,
            pageSpacing: 6,
            currentSearchTextHighlightColor: currentPalette.accent.withValues(alpha: 0.6),
            otherSearchTextHighlightColor: AppColors.highlightYellow,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              _totalPagesNotifier.value = details.document.pages.count;
            },
            onPageChanged: (PdfPageChangedDetails details) {
              if (!_isDraggingSlider) {
                _currentPageNotifier.value = details.newPageNumber;
                _sliderValNotifier.value = details.newPageNumber.toDouble();
              }
              _scheduleSaveProgress(details.newPageNumber);
            },
          ),

          // Bottom Navigation Slider & Info (Auto-padded for System Navigation Bar)
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: currentPalette.color.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: _totalPagesNotifier,
                builder: (context, totalPages, _) {
                  return ValueListenableBuilder<double>(
                    valueListenable: _sliderValNotifier,
                    builder: (context, sliderVal, _) {
                      final displayPage = sliderVal.toInt().clamp(1, totalPages > 0 ? totalPages : 1);
                      return Row(
                        children: [
                          Text(
                            '$displayPage',
                            style: GoogleFonts.ibmPlexSansArabic(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: currentPalette.accent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: currentPalette.accent,
                                overlayColor: currentPalette.accent.withValues(alpha: 0.2),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: sliderVal.clamp(1.0, totalPages > 0 ? totalPages.toDouble() : 1.0),
                                min: 1.0,
                                max: totalPages > 0 ? totalPages.toDouble() : 1.0,
                                onChangeStart: (val) {
                                  _isDraggingSlider = true;
                                },
                                onChanged: (val) {
                                  _sliderValNotifier.value = val;
                                  final page = val.toInt().clamp(1, totalPages);
                                  final now = DateTime.now();
                                  if (page != _lastJumpedPage &&
                                      now.difference(_lastJumpTime).inMilliseconds >= 80) {
                                    _lastJumpTime = now;
                                    _lastJumpedPage = page;
                                    _currentPageNotifier.value = page;
                                    _pdfController.jumpToPage(page);
                                  }
                                },
                                onChangeEnd: (val) {
                                  _isDraggingSlider = false;
                                  final page = val.toInt().clamp(1, totalPages);
                                  _currentPageNotifier.value = page;
                                  _sliderValNotifier.value = page.toDouble();
                                  _lastJumpedPage = page;
                                  _pdfController.jumpToPage(page);
                                  _scheduleSaveProgress(page);
                                },
                              ),
                            ),
                          ),
                          const Gap(8),
                          Text(
                            '$totalPages',
                            style: GoogleFonts.ibmPlexSansArabic(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
