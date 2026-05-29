class ApiConstants {
  static const String apiKey = 'adf3723b';

  static const String baseUrl = 'https://www.omdbapi.com/';

  static const String defaultType = 'movie'; // ou 'series'
  static const int resultsPerPage = 10;

  static const Duration apiTimeout = Duration(seconds: 10);
}
