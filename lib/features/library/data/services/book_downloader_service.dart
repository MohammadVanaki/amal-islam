import 'dart:developer' as developer;
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/book_model.dart';

enum BookDownloadStage {
  idle,
  downloading,
  extracting,
  ready,
  error,
}

class BookDownloadProgress {
  final BookDownloadStage stage;
  final double progress; // 0.0 to 1.0
  final int? receivedBytes;
  final int? totalBytes;
  final String? message;
  final String? filePath;
  final String? error;

  const BookDownloadProgress({
    required this.stage,
    required this.progress,
    this.receivedBytes,
    this.totalBytes,
    this.message,
    this.filePath,
    this.error,
  });

  @override
  String toString() =>
      'BookDownloadProgress(stage: $stage, progress: ${(progress * 100).toStringAsFixed(1)}%, received: $receivedBytes/$totalBytes)';
}

class _ZipExtractRequest {
  final String zipPath;
  final String dbTargetPath;
  final String? coverTargetPath;

  const _ZipExtractRequest({
    required this.zipPath,
    required this.dbTargetPath,
    this.coverTargetPath,
  });
}

/// Standalone top-level worker for background isolate execution via Flutter's compute().
/// Zero closure capture, zero UI thread freezing.
void _executeZipExtractWorker(_ZipExtractRequest req) {
  final zipFile = File(req.zipPath);
  if (!zipFile.existsSync()) {
    throw Exception('ملف الأرشيف المضغوط غير موجود على القرص');
  }

  final bytes = zipFile.readAsBytesSync();
  if (bytes.isEmpty) {
    throw Exception('ملف الأرشيف المضغوط فارغ');
  }

  final archive = ZipDecoder().decodeBytes(bytes);
  ArchiveFile? dbFile;
  ArchiveFile? coverFile;

  // Search archive entries (including subfolders)
  for (final file in archive) {
    if (file.isFile) {
      final lower = file.name.toLowerCase();
      if (lower.endsWith('.sqlite') || lower.endsWith('.db') || lower.endsWith('.sqlite3')) {
        dbFile = file;
      } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
        coverFile = file;
      }
    }
  }

  // Fallback: choose largest file in archive
  if (dbFile == null) {
    for (final file in archive) {
      if (file.isFile && (dbFile == null || file.size > dbFile.size)) {
        dbFile = file;
      }
    }
  }

  if (dbFile == null) {
    throw Exception('لم يتم العثور على قاعدة بيانات الكتاب داخل الحزمة المضغوطة');
  }

  // Write to temp file then rename with atomic flush
  final tempDb = File('${req.dbTargetPath}.tmp');
  if (tempDb.existsSync()) {
    tempDb.deleteSync();
  }

  tempDb.writeAsBytesSync(dbFile.content as List<int>, flush: true);

  final targetDb = File(req.dbTargetPath);
  if (targetDb.existsSync()) {
    targetDb.deleteSync();
  }
  tempDb.renameSync(req.dbTargetPath);

  // Save book cover if present
  if (coverFile != null && req.coverTargetPath != null) {
    try {
      final targetCover = File(req.coverTargetPath!);
      targetCover.writeAsBytesSync(coverFile.content as List<int>, flush: true);
    } catch (_) {}
  }
}

class BookDownloaderService {
  final Dio _dio = Dio();

  Future<String> _getBooksDirectory() async {
    final docDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(p.join(docDir.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }
    return booksDir.path;
  }

  Future<String> getBookFilePath(String bookId, BookType type) async {
    final dir = await _getBooksDirectory();
    if (type == BookType.pdf) {
      return p.join(dir, 'book_$bookId.pdf');
    } else {
      return p.join(dir, 'book_$bookId.db');
    }
  }

  Future<bool> isBookDownloaded(String bookId, BookType type) async {
    final path = await getBookFilePath(bookId, type);
    final file = File(path);
    if (await file.exists()) {
      final length = await file.length();
      return length > 1024;
    }
    return false;
  }

  Future<bool> isTextDownloaded(String bookId) async {
    return isBookDownloaded(bookId, BookType.sqliteDatabase);
  }

  Future<bool> isPdfDownloaded(String bookId) async {
    return isBookDownloaded(bookId, BookType.pdf);
  }

  Future<int> getDownloadedFilesTotalBytes() async {
    final dir = await _getBooksDirectory();
    final d = Directory(dir);
    if (!await d.exists()) return 0;
    int total = 0;
    await for (final file in d.list(recursive: false)) {
      if (file is File) {
        if (file.path.endsWith('.tmp')) continue;
        total += await file.length();
      }
    }
    return total;
  }

  Future<int> getBookFileSize(String bookId, BookType type) async {
    final path = await getBookFilePath(bookId, type);
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Primary architecture method:
  /// Downloads via stream to disk, validates magic bytes, unzips in background isolate, and caches final SQLite database.
  Future<String> downloadAndPrepareBook({
    required BookModel book,
    void Function(BookDownloadProgress progress)? onStatusChanged,
    CancelToken? cancelToken,
  }) async {
    final dir = await _getBooksDirectory();
    final dbTargetPath = p.join(dir, 'book_${book.id}.db');
    final coverTargetPath = p.join(dir, 'cover_${book.id}.jpg');
    final tempZipPath = p.join(dir, 'book_${book.id}.zip.tmp');
    final tempZipFile = File(tempZipPath);

    // 1. Cache & Readiness Check:
    final targetDbFile = File(dbTargetPath);
    if (await targetDbFile.exists()) {
      final length = await targetDbFile.length();
      if (length > 1024) {
        developer.log('Book ${book.id} is already cached on disk ($length bytes). Skipping download.', name: 'BookDownloader');
        onStatusChanged?.call(BookDownloadProgress(
          stage: BookDownloadStage.ready,
          progress: 1.0,
          filePath: dbTargetPath,
          message: 'الكتاب جاهز للقراءة',
        ));
        return dbTargetPath;
      }
    }

    // Clean up any stale partial files
    if (await tempZipFile.exists()) {
      await tempZipFile.delete();
    }

    final downloadUrl = (book.zipUrl != null &&
            book.zipUrl!.trim().isNotEmpty &&
            book.zipUrl!.startsWith('http'))
        ? book.zipUrl!
        : '${ApiConstants.baseUrl}${ApiConstants.bookDownloadEndpoint(book.id)}';

    developer.log('Starting stream download from: $downloadUrl', name: 'BookDownloader');

    onStatusChanged?.call(const BookDownloadProgress(
      stage: BookDownloadStage.downloading,
      progress: 0.01,
      message: 'جاري الاتصال بالخادم...',
    ));

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);

    bool isCancelled = false;
    HttpClientRequest? activeRequest;
    IOSink? fileSink;

    if (cancelToken != null) {
      cancelToken.whenCancel.then((_) {
        isCancelled = true;
        try {
          activeRequest?.abort();
          fileSink?.close();
        } catch (_) {}
      });
    }

    try {
      final uri = Uri.parse(downloadUrl);
      activeRequest = await client.getUrl(uri);

      // Required Headers
      activeRequest.headers.set(ApiConstants.apiKeyHeader, ApiConstants.apiKey);
      activeRequest.headers.set('Accept', 'application/zip, application/octet-stream, */*');
      activeRequest.headers.set('Accept-Encoding', 'identity');
      activeRequest.headers.set('User-Agent', 'Mozilla/5.0 (Mobile; FlutterApp)');

      final response = await activeRequest.close();

      // Validate Server Response
      if (response.statusCode != 200) {
        throw HttpException('استجاب الخادم برمز خطأ غير متوقع: ${response.statusCode}');
      }

      final contentType = response.headers.contentType?.mimeType.toLowerCase();
      if (contentType != null && contentType.contains('html')) {
        throw const HttpException('استجاب الخادم بصفحة خطأ HTML غير صالحة بدلاً من الملف');
      }

      fileSink = tempZipFile.openWrite(mode: FileMode.write);

      int receivedBytes = 0;
      final expectedLength = response.contentLength;
      int lastNotifyTime = 0;

      // Stream directly to disk: avoids loading raw file into RAM (Zero OOM)
      await for (final chunk in response) {
        if (isCancelled || (cancelToken != null && cancelToken.isCancelled)) {
          throw const FormatException('Cancelled by user');
        }

        fileSink.add(chunk);
        receivedBytes += chunk.length;

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastNotifyTime >= 250) {
          lastNotifyTime = now;
          double progress;
          if (expectedLength > 0) {
            progress = (receivedBytes / expectedLength) * 0.75;
          } else {
            progress = (receivedBytes / 180000).clamp(0.05, 0.75);
          }

          onStatusChanged?.call(BookDownloadProgress(
            stage: BookDownloadStage.downloading,
            progress: progress,
            receivedBytes: receivedBytes,
            totalBytes: expectedLength > 0 ? expectedLength : null,
            message: 'جاري تحميل الملف...',
          ));
        }
      }

      await fileSink.flush();
      await fileSink.close();
      fileSink = null;
      client.close();

      if (isCancelled || (cancelToken != null && cancelToken.isCancelled)) {
        throw const FormatException('Cancelled by user');
      }

      final downloadedFileSize = await tempZipFile.length();
      if (downloadedFileSize == 0) {
        throw Exception('الملف الذي تم تنزيله من الخادم فارغ');
      }

      // 2. Validate Magic Bytes:
      final magicBytes = await _readFirstBytes(tempZipFile, 16);
      final isZip = magicBytes.length >= 2 && magicBytes[0] == 0x50 && magicBytes[1] == 0x4B; // PK
      final isSqlite = magicBytes.length >= 15 &&
          String.fromCharCodes(magicBytes.sublist(0, 15)) == 'SQLite format 3';

      if (isZip) {
        // 3. Background Isolate Unzip using Flutter's compute:
        developer.log('Valid ZIP signature found ($downloadedFileSize bytes). Extracting in background isolate...', name: 'BookDownloader');

        onStatusChanged?.call(const BookDownloadProgress(
          stage: BookDownloadStage.extracting,
          progress: 0.80,
          message: 'جاري استخراج قاعدة بيانات الكتاب...',
        ));

        final extractReq = _ZipExtractRequest(
          zipPath: tempZipFile.path,
          dbTargetPath: dbTargetPath,
          coverTargetPath: coverTargetPath,
        );

        await compute(_executeZipExtractWorker, extractReq);

        // Delete temporary zip file immediately after successful extraction
        if (await tempZipFile.exists()) {
          await tempZipFile.delete();
        }
      } else if (isSqlite) {
        // Direct uncompressed SQLite database from server: rename directly
        developer.log('Direct SQLite signature found. Saving without unzip...', name: 'BookDownloader');
        if (await targetDbFile.exists()) {
          await targetDbFile.delete();
        }
        await tempZipFile.rename(dbTargetPath);
      } else {
        if (await tempZipFile.exists()) {
          await tempZipFile.delete();
        }
        throw Exception('الملف المستلم ليس ملف ZIP أو قاعدة بيانات SQLite صالحة');
      }

      // Verify final target database on disk
      if (!await targetDbFile.exists() || (await targetDbFile.length()) == 0) {
        throw Exception('فشل تثبيت قاعدة بيانات الكتاب على القرص');
      }

      onStatusChanged?.call(BookDownloadProgress(
        stage: BookDownloadStage.ready,
        progress: 1.0,
        filePath: dbTargetPath,
        message: 'تم إعداد الكتاب وهو جاهز للمطالعة',
      ));

      developer.log('Book ${book.id} successfully ready at $dbTargetPath', name: 'BookDownloader');
      return dbTargetPath;
    } catch (e) {
      client.close(force: true);
      try {
        await fileSink?.close();
      } catch (_) {}

      // Immediate cleanup of partial/corrupt temp files
      try {
        if (await tempZipFile.exists()) {
          await tempZipFile.delete();
        }
        final tempDb = File('$dbTargetPath.tmp');
        if (await tempDb.exists()) {
          await tempDb.delete();
        }
      } catch (_) {}

      final isCancel = isCancelled ||
          (cancelToken != null && cancelToken.isCancelled) ||
          e.toString().contains('Cancelled') ||
          e.toString().contains('abort');

      if (isCancel) {
        developer.log('Download was cancelled by user for book ${book.id}', name: 'BookDownloader');
      } else {
        developer.log('Error downloading/preparing book ${book.id}: $e', name: 'BookDownloader');
        onStatusChanged?.call(BookDownloadProgress(
          stage: BookDownloadStage.error,
          progress: 0.0,
          error: e.toString(),
          message: 'تعذر تنزيل الكتاب: $e',
        ));
      }
      rethrow;
    }
  }

  /// Backward-compatible adapter for existing download providers and UI screens
  Future<void> downloadTextBook({
    required BookModel book,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    await downloadAndPrepareBook(
      book: book,
      cancelToken: cancelToken,
      onStatusChanged: (progressInfo) {
        onProgress(progressInfo.progress);
      },
    );
  }

  /// Reads the first N bytes of a file to inspect magic numbers without loading the whole file into RAM
  static Future<Uint8List> _readFirstBytes(File file, int byteCount) async {
    final stream = file.openRead(0, byteCount);
    final bytes = <int>[];
    await for (final chunk in stream) {
      bytes.addAll(chunk);
      if (bytes.length >= byteCount) break;
    }
    return Uint8List.fromList(bytes.take(byteCount).toList());
  }

  /// Downloads raw PDF file using streamed disk writing
  Future<void> downloadPdfBook({
    required BookModel book,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (book.pdfUrl == null || book.pdfUrl!.isEmpty) {
      throw Exception('لا يتوفر رابط PDF لهذا الكتاب');
    }

    final dir = await _getBooksDirectory();
    final targetPath = p.join(dir, 'book_${book.id}.pdf');
    final tempPath = '$targetPath.temp';

    // Cache check
    final targetFile = File(targetPath);
    if (await targetFile.exists() && (await targetFile.length()) > 1024) {
      onProgress(1.0);
      return;
    }

    developer.log('Starting PDF stream download from: ${book.pdfUrl}', name: 'BookDownloader');

    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    await _dio.download(
      book.pdfUrl!,
      tempPath,
      cancelToken: cancelToken,
      options: Options(
        followRedirects: true,
        headers: {
          'Accept': 'application/pdf, application/octet-stream, */*',
          'Accept-Encoding': 'identity',
          'User-Agent': 'Mozilla/5.0 (Mobile; FlutterApp)',
        },
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(seconds: 30),
      ),
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress((received / total).clamp(0.0, 1.0));
        } else {
          onProgress(0.5);
        }
      },
    );

    if (await tempFile.exists()) {
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetPath);
      developer.log('PDF saved at: $targetPath', name: 'BookDownloader');
    }

    onProgress(1.0);
  }

  Future<void> downloadBook({
    required BookModel book,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    await downloadTextBook(
      book: book,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> deleteBook(String bookId, BookType type) async {
    final path = await getBookFilePath(bookId, type);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deletePdf(String bookId) async {
    await deleteBook(bookId, BookType.pdf);
  }

  Future<void> deleteText(String bookId) async {
    await deleteBook(bookId, BookType.sqliteDatabase);
  }
}
