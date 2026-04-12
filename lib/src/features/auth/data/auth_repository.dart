import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booklybear/src/utils/dio_client.dart';


class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // Call POST /api/auth/login
  Future<String> login({required String email, required String password}) async {
    try {
      print('--- [AUTH] Attempting login for: $email');
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      print('--- [AUTH] Login successful');
      return response.data['token'];
    } on DioException catch (e) {
      print('--- [AUTH] Login ERROR: ${e.type} - ${e.message}');
      if (e.error != null) print('--- [AUTH] Details: ${e.error}');
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  // Call POST /api/auth/register
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print('--- [AUTH] Attempting registration for: $username ($email)');
      await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      print('--- [AUTH] Registration successful');
    } on DioException catch (e) {
      print('--- [AUTH] Registration ERROR: ${e.type} - ${e.message}');
      if (e.error != null) print('--- [AUTH] Details: ${e.error}');
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }
}

// Provider so other files can find this repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});