import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/book_model.dart';
import '../data/services/book_downloader_service.dart';
import 'library_provider.dart';

class BookDownloadState {
  final bool isDownloading;
  final double progress;
  final bool isDownloaded;
  final String? error;

  const BookDownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.isDownloaded = false,
    this.error,
  });

  BookDownloadState copyWith({
    bool? isDownloading,
    double? progress,
    bool? isDownloaded,
    String? error,
  }) {
    return BookDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookDownloadState &&
          runtimeType == other.runtimeType &&
          isDownloading == other.isDownloading &&
          progress == other.progress &&
          isDownloaded == other.isDownloaded &&
          error == other.error;

  @override
  int get hashCode => Object.hash(isDownloading, progress, isDownloaded, error);
}

final bookDownloaderServiceProvider = Provider<BookDownloaderService>((ref) {
  return BookDownloaderService();
});

class DownloadManagerNotifier extends StateNotifier<Map<String, BookDownloadState>> {
  final BookDownloaderService _service;
  final Ref _ref;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadManagerNotifier(this._service, this._ref) : super({});

  Future<void> checkStatus(String bookId, BookType type, {bool force = false}) async {
    final key = type == BookType.pdf ? 'pdf_$bookId' : bookId;
    if (!force && state.containsKey(key)) return;

    final downloaded = await _service.isBookDownloaded(bookId, type);
    final current = state[key] ?? const BookDownloadState();
    if (current.isDownloaded == downloaded && state.containsKey(key)) return;

    state = {
      ...state,
      key: current.copyWith(isDownloaded: downloaded),
    };
  }

  Future<void> checkAllStatuses(String bookId, {bool force = false}) async {
    final textKey = bookId;
    final pdfKey = 'pdf_$bookId';

    if (!force && state.containsKey(textKey) && state.containsKey(pdfKey)) return;

    final hasText = await _service.isTextDownloaded(bookId);
    final hasPdf = await _service.isPdfDownloaded(bookId);

    final currentText = state[textKey] ?? const BookDownloadState();
    final currentPdf = state[pdfKey] ?? const BookDownloadState();

    if (state.containsKey(textKey) &&
        state.containsKey(pdfKey) &&
        currentText.isDownloaded == hasText &&
        currentPdf.isDownloaded == hasPdf) {
      return;
    }

    state = {
      ...state,
      textKey: currentText.copyWith(isDownloaded: hasText),
      pdfKey: currentPdf.copyWith(isDownloaded: hasPdf),
    };
  }

  /// Downloads the text book into SQLite (Default & First priority)
  Future<void> startDownload(BookModel book) async {
    final key = book.id;
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;

    state = {
      ...state,
      key: const BookDownloadState(isDownloading: true, progress: 0.01),
    };

    int lastNotifyTime = 0;

    try {
      await _service.downloadTextBook(
        book: book,
        cancelToken: cancelToken,
        onProgress: (progress) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Throttle state update to avoid overwhelming the Flutter rendering pipeline
          if (progress >= 1.0 || (now - lastNotifyTime >= 200)) {
            lastNotifyTime = now;
            state = {
              ...state,
              key: BookDownloadState(
                isDownloading: true,
                progress: progress,
                isDownloaded: false,
              ),
            };
          }
        },
      );

      state = {
        ...state,
        key: const BookDownloadState(
          isDownloading: false,
          progress: 1.0,
          isDownloaded: true,
        ),
      };
      developer.log('Text download completed for book ${book.id}', name: 'DownloadManager');
      _ref.invalidate(downloadedBooksProvider);
      _ref.invalidate(totalStorageBytesProvider);
    } catch (e) {
      final isCancel = cancelToken.isCancelled ||
          e.toString().contains('Cancelled') ||
          e.toString().contains('abort') ||
          (e is DioException && CancelToken.isCancel(e));

      if (isCancel) {
        developer.log('Download was cancelled by user for book ${book.id}', name: 'DownloadManager');
        state = {
          ...state,
          key: const BookDownloadState(
            isDownloading: false,
            progress: 0.0,
            isDownloaded: false,
            error: null,
          ),
        };
      } else {
        developer.log('Text download failed for book ${book.id}: $e', name: 'DownloadManager');
        state = {
          ...state,
          key: BookDownloadState(
            isDownloading: false,
            progress: 0.0,
            isDownloaded: false,
            error: e.toString(),
          ),
        };
      }
    } finally {
      _cancelTokens.remove(key);
    }
  }

  /// Downloads the PDF version (Secondary option)
  Future<void> startDownloadPdf(BookModel book) async {
    final key = 'pdf_${book.id}';
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;

    state = {
      ...state,
      key: const BookDownloadState(isDownloading: true, progress: 0.01),
    };

    int lastNotifyTime = 0;

    try {
      await _service.downloadPdfBook(
        book: book,
        cancelToken: cancelToken,
        onProgress: (progress) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (progress >= 1.0 || (now - lastNotifyTime >= 200)) {
            lastNotifyTime = now;
            state = {
              ...state,
              key: BookDownloadState(
                isDownloading: true,
                progress: progress,
                isDownloaded: false,
              ),
            };
          }
        },
      );

      state = {
        ...state,
        key: const BookDownloadState(
          isDownloading: false,
          progress: 1.0,
          isDownloaded: true,
        ),
      };
      developer.log('PDF download completed for book ${book.id}', name: 'DownloadManager');
      _ref.invalidate(downloadedBooksProvider);
      _ref.invalidate(totalStorageBytesProvider);
    } catch (e) {
      final isCancel = cancelToken.isCancelled ||
          e.toString().contains('Cancelled') ||
          e.toString().contains('abort') ||
          (e is DioException && CancelToken.isCancel(e));

      if (isCancel) {
        developer.log('PDF download was cancelled by user for book ${book.id}', name: 'DownloadManager');
        state = {
          ...state,
          key: const BookDownloadState(
            isDownloading: false,
            progress: 0.0,
            isDownloaded: false,
            error: null,
          ),
        };
      } else {
        developer.log('PDF download failed for book ${book.id}: $e', name: 'DownloadManager');
        state = {
          ...state,
          key: BookDownloadState(
            isDownloading: false,
            progress: 0.0,
            isDownloaded: false,
            error: e.toString(),
          ),
        };
      }
    } finally {
      _cancelTokens.remove(key);
    }
  }

  void cancelDownload(String key) {
    if (_cancelTokens.containsKey(key)) {
      _cancelTokens[key]?.cancel('Cancelled by user');
      _cancelTokens.remove(key);
    }
    state = {
      ...state,
      key: const BookDownloadState(
        isDownloading: false,
        progress: 0.0,
        isDownloaded: false,
        error: null,
      ),
    };
  }

  Future<void> deleteBook(BookModel book) async {
    await _service.deleteText(book.id);
    state = {
      ...state,
      book.id: const BookDownloadState(isDownloaded: false, progress: 0.0),
    };
    _ref.invalidate(downloadedBooksProvider);
    _ref.invalidate(totalStorageBytesProvider);
  }

  Future<void> deletePdf(BookModel book) async {
    await _service.deletePdf(book.id);
    state = {
      ...state,
      'pdf_${book.id}': const BookDownloadState(isDownloaded: false, progress: 0.0),
    };
    _ref.invalidate(downloadedBooksProvider);
    _ref.invalidate(totalStorageBytesProvider);
  }
}

final downloadManagerProvider =
    StateNotifierProvider<DownloadManagerNotifier, Map<String, BookDownloadState>>((ref) {
  final service = ref.watch(bookDownloaderServiceProvider);
  return DownloadManagerNotifier(service, ref);
});

final singleBookDownloadProvider = Provider.family<BookDownloadState, String>((ref, bookId) {
  return ref.watch(downloadManagerProvider.select((map) => map[bookId] ?? const BookDownloadState()));
});

final singlePdfDownloadProvider = Provider.family<BookDownloadState, String>((ref, bookId) {
  return ref.watch(downloadManagerProvider.select((map) => map['pdf_$bookId'] ?? const BookDownloadState()));
});

final downloadedBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  // Do NOT watch downloadManagerProvider here.
  // downloadManagerProvider emits progress updates multiple times per second during download.
  // Invalidation is triggered explicitly when download completes or book is deleted.
  final allBooks = await ref.watch(booksFutureProvider.future);
  final service = ref.watch(bookDownloaderServiceProvider);

  final list = <BookModel>[];
  for (final b in allBooks) {
    final hasText = await service.isTextDownloaded(b.id);
    final hasPdf = await service.isPdfDownloaded(b.id);
    if (hasText || hasPdf) {
      list.add(b);
    }
  }
  return list;
});

final totalStorageBytesProvider = FutureProvider<int>((ref) async {
  // Invalidation is triggered explicitly when download completes or book is deleted.
  final service = ref.watch(bookDownloaderServiceProvider);
  return await service.getDownloadedFilesTotalBytes();
});
