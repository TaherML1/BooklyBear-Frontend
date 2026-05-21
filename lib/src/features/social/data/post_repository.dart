import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/post.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(dioProvider));
});

final timelineProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  final repo = ref.watch(postRepositoryProvider);
  return repo.getTimeline();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(postRepositoryProvider);
  return repo.getUnreadCount();
});

class PostRepository {
  final Dio _dio;

  PostRepository(this._dio);

  Future<List<Post>> getTimeline() async {
    try {
      final response = await _dio.get('/posts/timeline');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as List<dynamic>;
        return data.map((json) => Post.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Post> createPost(String content, {String? bookId, List<String>? tags}) async {
    try {
      final data = <String, dynamic>{'content': content};
      if (bookId != null) data['bookId'] = bookId;
      if (tags != null) data['tags'] = tags;
      final response = await _dio.post('/posts', data: data);
      return Post.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create post';
    }
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final response = await _dio.post('/posts/$postId/like');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to toggle like';
    }
  }

  Future<List<PostComment>> getComments(String postId) async {
    try {
      final response = await _dio.get('/posts/$postId/comments');
      final data = response.data as List<dynamic>;
      return data.map((json) => PostComment.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load comments';
    }
  }

  Future<PostComment> addComment(String postId, String content) async {
    try {
      final response = await _dio.post('/posts/$postId/comments', data: {'content': content});
      return PostComment.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to add comment';
    }
  }

  Future<void> markPostsAsRead(List<String> postIds) async {
    try {
      await _dio.post('/posts/mark-read', data: {'postIds': postIds});
    } catch (_) {}
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/posts/unread-count');
      return response.data['unreadCount'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
