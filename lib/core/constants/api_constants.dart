class ApiConstants {
  static const String baseUrl = 'https://library.dijlah.org/api/v1';
  static const String apiKey = '68lJm6NY1ZJcYzQWyKf3N83zZcLh9lNS';
  static const String apiKeyHeader = 'x-api-key';

  static const String booksEndpoint = '/books';
  static const String homeEndpoint = '/home';
  static String bookDownloadEndpoint(dynamic bookId) => '/book/download/$bookId';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
