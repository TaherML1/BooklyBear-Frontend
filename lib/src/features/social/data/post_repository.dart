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
}
