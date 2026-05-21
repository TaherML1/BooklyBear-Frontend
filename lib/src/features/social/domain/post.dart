import '../../books/domain/book.dart';

class Post {
  final String id;
  final String content;
  final PostAuthor user;
  final Book? book;
  final DateTime createdAt;
  int likeCount;
  bool isLiked;
  int commentCount;
  final bool isDiscovery;
  final List<String> tags;

  Post({
    required this.id,
    required this.content,
    required this.user,
    this.book,
    required this.createdAt,
    required this.likeCount,
    this.isLiked = false,
    this.commentCount = 0,
    this.isDiscovery = false,
    this.tags = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      content: json['content'] as String,
      user: PostAuthor.fromJson(json['user'] as Map<String, dynamic>),
      book: json['book'] != null ? Book.fromJson(json['book'] as Map<String, dynamic>) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: json['likeCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      commentCount: json['commentCount'] as int? ?? 0,
      isDiscovery: json['isDiscovery'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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

class PostComment {
  final String id;
  final String content;
  final PostAuthor user;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.content,
    required this.user,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      content: json['content'] as String,
      user: PostAuthor.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
