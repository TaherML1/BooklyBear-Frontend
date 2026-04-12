import '../domain/reading_group.dart';

class MemberProgress {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int currentPage;
  final int totalPages;
  final int percentage;
  final String status;

  MemberProgress({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.currentPage,
    required this.totalPages,
    required this.percentage,
    required this.status,
  });

  factory MemberProgress.fromJson(Map<String, dynamic> json) {
    return MemberProgress(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'],
      currentPage: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      percentage: (json['percentage'] as num).toInt(),
      status: json['status'] ?? 'not_started',
    );
  }
}

class GroupProgressData {
  final Map<String, dynamic>? currentBook;
  final List<MemberProgress> members;

  GroupProgressData({this.currentBook, required this.members});

  factory GroupProgressData.fromJson(Map<String, dynamic> json) {
    return GroupProgressData(
      currentBook: json['currentBook'],
      members: (json['members'] as List?)
              ?.map((e) => MemberProgress.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int pagesRead;
  final int minutesSpent;
  final int sessionsCount;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.pagesRead,
    required this.minutesSpent,
    required this.sessionsCount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'],
      pagesRead: (json['pagesRead'] as num).toInt(),
      minutesSpent: (json['minutesSpent'] as num).toInt(),
      sessionsCount: (json['sessionsCount'] as num).toInt(),
    );
  }
}

class GroupStats {
  final int memberCount;
  final int totalPagesRead;
  final int totalMinutesSpent;
  final int totalHours;
  final int totalSessions;
  final int booksFinished;
  final Map<String, dynamic> mostActiveReader;

  GroupStats({
    required this.memberCount,
    required this.totalPagesRead,
    required this.totalMinutesSpent,
    required this.totalHours,
    required this.totalSessions,
    required this.booksFinished,
    required this.mostActiveReader,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      memberCount: (json['memberCount'] as num? ?? 0).toInt(),
      totalPagesRead: (json['totalPagesRead'] as num? ?? 0).toInt(),
      totalMinutesSpent: (json['totalMinutesSpent'] as num? ?? 0).toInt(),
      totalHours: (json['totalHours'] as num? ?? 0).toInt(),
      totalSessions: (json['totalSessions'] as num? ?? 0).toInt(),
      booksFinished: (json['booksFinished'] as num? ?? 0).toInt(),
      mostActiveReader: Map<String, dynamic>.from(json['mostActiveReader'] ?? {}),
    );
  }
}

enum ActivityType {
  pages_read,
  book_finished,
  member_joined,
  member_left,
  book_selected,
  milestone_created,
  vote_cast,
  book_proposed,
}

class GroupActivity {
  final String id;
  final ActivityType type;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final GroupMemberUser user;

  GroupActivity({
    required this.id,
    required this.type,
    required this.metadata,
    required this.createdAt,
    required this.user,
  });

  factory GroupActivity.fromJson(Map<String, dynamic> json) {
    return GroupActivity(
      id: json['id'] ?? '',
      type: ActivityType.values.byName(json['type']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      user: GroupMemberUser.fromJson(json['user']),
    );
  }
}

class BookProposal {
  final String id;
  final Map<String, dynamic> book;
  final Map<String, dynamic> proposedBy;
  final int voteCount;
  final bool hasVoted;
  final DateTime createdAt;

  BookProposal({
    required this.id,
    required this.book,
    required this.proposedBy,
    required this.voteCount,
    required this.hasVoted,
    required this.createdAt,
  });

  factory BookProposal.fromJson(Map<String, dynamic> json) {
    return BookProposal(
      id: json['id'] ?? '',
      book: Map<String, dynamic>.from(json['book'] ?? {}),
      proposedBy: Map<String, dynamic>.from(json['proposedBy'] ?? {}),
      voteCount: (json['voteCount'] as num? ?? 0).toInt(),
      hasVoted: json['hasVoted'] == true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ReadingMilestone {
  final String id;
  final String title;
  final int targetPage;
  final DateTime deadline;
  final DateTime createdAt;
  final bool isCompleted;
  final bool isOverdue;
  final int myCurrentPage;

  ReadingMilestone({
    required this.id,
    required this.title,
    required this.targetPage,
    required this.deadline,
    required this.createdAt,
    required this.isCompleted,
    required this.isOverdue,
    required this.myCurrentPage,
  });

  factory ReadingMilestone.fromJson(Map<String, dynamic> json) {
    return ReadingMilestone(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      targetPage: (json['targetPage'] as num).toInt(),
      deadline: DateTime.parse(json['deadline']),
      createdAt: DateTime.parse(json['createdAt']),
      isCompleted: json['isCompleted'] == true,
      isOverdue: json['isOverdue'] == true,
      myCurrentPage: (json['myCurrentPage'] as num? ?? 0).toInt(),
    );
  }
}
