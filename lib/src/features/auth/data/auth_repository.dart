import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booklybear/src/utils/dio_client.dart';


class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  // Call POST /api/auth/login
  Future<String> login({required String email, required String password}) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // Your backend returns { "token": "..." }
      return response.data['token'];
    } on DioException catch (e) {
      // Helper to extract backend error message like "Invalid credentials"
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
      await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      // We don't need to return anything on success, just not throw error
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Registration failed';
    }
  }
}

// Provider so other files can find this repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});