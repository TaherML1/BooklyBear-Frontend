import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_logger.dart';

String apiBaseUrl = 'http://192.168.1.76:3000/api'; // Fallback

String getApiBaseUrl() {
  AppLogger.info('--- [CONFIG] Using API Base URL: $apiBaseUrl');
  return apiBaseUrl;
}

Future<void> fetchDynamicApiUrl() async {
  try {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
    // Add a query param with timestamp to bypass GitHub caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final response = await dio.get('https://raw.githubusercontent.com/TaherML1/BooklyBear-Frontend/main/api_url.txt?t=$timestamp');
    
    if (response.statusCode == 200 && response.data != null) {
      final fetchedUrl = response.data.toString().trim();
      if (fetchedUrl.isNotEmpty) {
        apiBaseUrl = fetchedUrl;
        AppLogger.info('--- [CONFIG] Successfully fetched Dynamic API URL: $apiBaseUrl');
        return;
      }
    }
  } catch (e) {
    AppLogger.info('--- [CONFIG] Failed to fetch dynamic API URL, using fallback ($apiBaseUrl). Error: $e');
  }
}

// 1. Provider for the Storage
final storageProvider = Provider((ref) => const FlutterSecureStorage());

// 2. Provider for the Dio Client
final dioProvider = Provider((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: getApiBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final storage = ref.read(storageProvider);

  // Interceptor to inject Token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle 401 Unauthorized (Logout user) here later
        return handler.next(e);
      },
    ),
  );

  // 3. Log ALL requests and responses to the Flutter console
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => AppLogger.debug('--- [DIO] $obj'),
    ),
  );

  return dio;
});
