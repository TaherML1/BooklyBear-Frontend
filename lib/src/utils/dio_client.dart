import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String getApiBaseUrl() {
  // Android / iOS physical device needs the PC's actual LAN IP
  return 'http://192.168.1.76:3000/api';
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

  return dio;
});
