class ReadingGroup {
  final String id;
  final String name;
  final String? description;
  final bool isPrivate;
  final String? groupAvatarUrl;
  final String? currentBookId;
  final int memberCount;
  final String? myRole;
  final DateTime? createdAt;

  ReadingGroup({
    required this.id,
    required this.name,
    this.description,
    this.isPrivate = false,
    this.groupAvatarUrl,
    this.currentBookId,
    this.memberCount = 0,
    this.myRole,
    this.createdAt,
  });

  factory ReadingGroup.fromJson(Map<String, dynamic> json) {
    return ReadingGroup(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isPrivate: json['isPrivate'] == true,
      groupAvatarUrl: json['groupAvatarUrl']?.toString(),
      currentBookId: json['currentBookId']?.toString(),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      myRole: json['myRole']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class GroupMemberUser {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  GroupMemberUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory GroupMemberUser.fromJson(Map<String, dynamic> json) {
    return GroupMemberUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class ReadingGroupMember {
  final String id;
  final String role;
  final DateTime? joinedAt;
  final GroupMemberUser user;

  ReadingGroupMember({
    required this.id,
    required this.role,
    this.joinedAt,
    required this.user,
  });

  factory ReadingGroupMember.fromJson(Map<String, dynamic> json) {
    return ReadingGroupMember(
      id: json['id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'].toString()) : null,
      user: GroupMemberUser.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class ReadingGroupDetails {
  final String id;
  final String name;
  final String? description;
  final bool isPrivate;
  final String? groupAvatarUrl;
  final String? currentBookId;
  final List<ReadingGroupMember> members;
  final DateTime? createdAt;

  ReadingGroupDetails({
    required this.id,
    required this.name,
    this.description,
    this.isPrivate = false,
    this.groupAvatarUrl,
    this.currentBookId,
    this.members = const [],
    this.createdAt,
  });

  factory ReadingGroupDetails.fromJson(Map<String, dynamic> json) {
    return ReadingGroupDetails(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isPrivate: json['isPrivate'] == true,
      groupAvatarUrl: json['groupAvatarUrl']?.toString(),
      currentBookId: json['currentBookId']?.toString(),
      members: (json['members'] as List?)
              ?.map((e) => ReadingGroupMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}
