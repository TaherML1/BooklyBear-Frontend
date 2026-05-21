/// A single discussion post within a reading group.
class GroupDiscussion {
  final String id;
  final String content;
  final bool spoilerTag;
  final int? pageReference;
  final DateTime createdAt;
  final GroupDiscussionUser user;

  GroupDiscussion({
    required this.id,
    required this.content,
    required this.spoilerTag,
    this.pageReference,
    required this.createdAt,
    required this.user,
  });

  factory GroupDiscussion.fromJson(Map<String, dynamic> json) {
    return GroupDiscussion(
      id: json['id'] as String,
      content: json['content'] as String,
      spoilerTag: json['spoilerTag'] as bool? ?? false,
      pageReference: json['pageReference'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: GroupDiscussionUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class GroupDiscussionUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  GroupDiscussionUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory GroupDiscussionUser.fromJson(Map<String, dynamic> json) {
    return GroupDiscussionUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
