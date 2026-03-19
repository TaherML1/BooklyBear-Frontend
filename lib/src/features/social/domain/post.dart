import '../../books/domain/book.dart';

class Post {
  final String id;
  final String content;
  final PostAuthor user;
  final Book? book;
  final DateTime createdAt;
  final int likeCount;
  final bool isDiscovery;

  Post({
    required this.id,
    required this.content,
    required this.user,
    this.book,
    required this.createdAt,
    required this.likeCount,
    this.isDiscovery = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      content: json['content'] as String,
      user: PostAuthor.fromJson(json['user'] as Map<String, dynamic>),
      book: json['book'] != null ? Book.fromJson(json['book'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      isDiscovery: json['isDiscovery'] as bool? ?? false,
    );
  }
}

class PostAuthor {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  PostAuthor({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
