import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/friendship.dart';

class FriendsRepository {
  final Dio _dio;
  FriendsRepository(this._dio);

  Future<List<FriendProfile>> getMyFriends() async {
    try {
      final res = await _dio.get('/friends/me');
      final list = res.data as List;
      return list.map((e) => FriendProfile.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load friends';
    }
  }

  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      final res = await _dio.get('/friends/requests');
      final list = res.data as List;
      return list.map((e) => FriendRequest.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load friend requests';
    }
  }

  Future<FriendshipStatusResponse> getFriendshipStatus(String userId) async {
    try {
      final res = await _dio.get('/friends/status/$userId');
      return FriendshipStatusResponse.fromJson(res.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to get friendship status';
    }
  }

  Future<void> sendFriendRequest(String username) async {
    try {
      await _dio.post('/friends/request/$username');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to send request';
    }
  }

  Future<void> acceptRequest(String friendshipId) async {
    try {
      await _dio.put('/friends/accept/$friendshipId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to accept request';
    }
  }

  Future<void> rejectRequest(String friendshipId) async {
    try {
      await _dio.delete('/friends/reject/$friendshipId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to reject request';
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      await _dio.delete('/friends/$friendshipId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to remove friend';
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _dio.post('/friends/block/$userId');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to block user';
    }
  }
}

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository(ref.read(dioProvider));
});

final myFriendsProvider = FutureProvider.autoDispose<List<FriendProfile>>((ref) {
  return ref.watch(friendsRepositoryProvider).getMyFriends();
});

final pendingRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((ref) {
  return ref.watch(friendsRepositoryProvider).getPendingRequests();
});

final friendshipStatusProvider = FutureProvider.autoDispose.family<FriendshipStatusResponse, String>((ref, userId) {
  return ref.watch(friendsRepositoryProvider).getFriendshipStatus(userId);
});
