class FriendProfile {
  final String friendshipId;
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  FriendProfile({
    required this.friendshipId,
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    return FriendProfile(
      friendshipId: json['friendshipId']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class FriendRequest {
  final String id;
  final String status;
  final FriendProfile requester;
  final DateTime? createdAt;

  FriendRequest({
    required this.id,
    required this.status,
    required this.requester,
    this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requester: FriendProfile.fromJson(json['requester'] as Map<String, dynamic>? ?? {}),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class FriendshipStatusResponse {
  final String status;
  final String? friendshipId;
  final String? requesterId;
  final String? receiverId;

  FriendshipStatusResponse({
    required this.status,
    this.friendshipId,
    this.requesterId,
    this.receiverId,
  });

  factory FriendshipStatusResponse.fromJson(Map<String, dynamic> json) {
    return FriendshipStatusResponse(
      status: json['status']?.toString() ?? 'none',
      friendshipId: json['friendshipId']?.toString(),
      requesterId: json['requesterId']?.toString(),
      receiverId: json['receiverId']?.toString(),
    );
  }
}
