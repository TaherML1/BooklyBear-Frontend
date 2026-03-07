import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/user.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  /// Fetches the logged-in user's profile data
  Future<User> getMyProfile() async {
    try {
      final response = await _dio.get('/user/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load profile';
    }
  }

  /// Updates display name and/or bio
  Future<User> updateMyProfile({String? displayName, String? bio}) async {
    try {
      final response = await _dio.put('/user/me', data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
      });
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update profile';
    }
  }
}

// 1. Provider for the Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioProvider));
});

// 2. A FutureProvider that fetches the user's profile
// This will be watched by our UI and will cache the data
final myProfileProvider = FutureProvider<User>((ref) {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});