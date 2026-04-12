import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String getApiBaseUrl() {
  // Updated to match your PC's actual IPv4 address
  const url = 'http://192.168.1.68:3000/api';
  print('--- [CONFIG] Using API Base URL: $url');
  return url;
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
      logPrint: (obj) => print('--- [DIO] $obj'),
    ),
  );

  return dio;
});
