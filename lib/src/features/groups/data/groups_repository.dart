import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/reading_group.dart';
import '../domain/group_features.dart';

class GroupsRepository {
  final Dio _dio;
  GroupsRepository(this._dio);

  Future<List<ReadingGroup>> getAllGroups() async {
    try {
      final res = await _dio.get('/groups');
      final list = res.data as List;
      return list.map((e) => ReadingGroup.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load groups';
    }
  }

  Future<List<ReadingGroup>> getMyGroups() async {
    try {
      final res = await _dio.get('/groups/me');
      final list = res.data as List;
      return list.map((e) => ReadingGroup.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load your groups';
    }
  }

  Future<ReadingGroupDetails> getGroupDetails(String groupId) async {
    try {
      final res = await _dio.get('/groups/$groupId');
      return ReadingGroupDetails.fromJson(res.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load group details';
    }
  }

  Future<ReadingGroup> createGroup(String name, String description, bool isPrivate) async {
    try {
      final res = await _dio.post('/groups', data: {
        'name': name,
        'description': description,
        'isPrivate': isPrivate,
      });
      return ReadingGroup.fromJson(res.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create group';
    }
  }

  Future<void> joinGroup(String groupId) async {
    try {
      await _dio.post('/groups/$groupId/join');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to join group';
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      await _dio.post('/groups/$groupId/leave');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to leave group';
    }
  }

  Future<void> setCurrentBook(String groupId, String bookId) async {
    try {
      await _dio.put('/groups/$groupId/book', data: {'bookId': bookId});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to set current book';
    }
  }

  // ── New Advanced Features ─────────────────────

  Future<GroupProgressData> getGroupProgress(String groupId) async {
    try {
      final res = await _dio.get('/groups/$groupId/progress');
      return GroupProgressData.fromJson(res.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load progress';
    }
  }

  Future<List<LeaderboardEntry>> getGroupLeaderboard(String groupId, {String period = 'weekly'}) async {
    try {
      final res = await _dio.get('/groups/$groupId/leaderboard', queryParameters: {'period': period});
      final list = res.data['leaderboard'] as List;
      return list.map((e) => LeaderboardEntry.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load leaderboard';
    }
  }

  Future<GroupStats> getGroupStats(String groupId) async {
    try {
      final res = await _dio.get('/groups/$groupId/stats');
      return GroupStats.fromJson(res.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load stats';
    }
  }

  Future<List<GroupActivity>> getGroupActivity(String groupId) async {
    try {
      final res = await _dio.get('/groups/$groupId/activity');
      final list = res.data as List;
      return list.map((e) => GroupActivity.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load activity feed';
    }
  }

  Future<void> proposeBook(String groupId, String bookId) async {
    try {
      await _dio.post('/groups/$groupId/proposals', data: {'bookId': bookId});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to propose book';
    }
  }

  Future<List<BookProposal>> getProposals(String groupId) async {
    try {
      final res = await _dio.get('/groups/$groupId/proposals');
      final list = res.data as List;
      return list.map((e) => BookProposal.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load proposals';
    }
  }

  Future<void> voteForProposal(String groupId, String proposalId) async {
    try {
      await _dio.post('/groups/$groupId/proposals/$proposalId/vote');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to vote';
    }
  }

  Future<void> removeVote(String groupId, String proposalId) async {
    try {
      await _dio.delete('/groups/$groupId/proposals/$proposalId/vote');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to remove vote';
    }
  }

  Future<void> selectProposal(String groupId, String proposalId) async {
    try {
      await _dio.post('/groups/$groupId/proposals/$proposalId/select');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to select book';
    }
  }

  Future<void> createMilestone(String groupId, String title, int targetPage, DateTime deadline) async {
    try {
      await _dio.post('/groups/$groupId/milestones', data: {
        'title': title,
        'targetPage': targetPage,
        'deadline': deadline.toIso8601String(),
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create milestone';
    }
  }

  Future<List<ReadingMilestone>> getMilestones(String groupId) async {
    try {
      final res = await _dio.get('/groups/$groupId/milestones');
      final list = res.data as List;
      return list.map((e) => ReadingMilestone.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load milestones';
    }
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.read(dioProvider));
});

// ── Basic List Providers ───────────────────────

final allGroupsProvider = FutureProvider.autoDispose<List<ReadingGroup>>((ref) {
  return ref.watch(groupsRepositoryProvider).getAllGroups();
});

final myGroupsProvider = FutureProvider.autoDispose<List<ReadingGroup>>((ref) {
  return ref.watch(groupsRepositoryProvider).getMyGroups();
});

final groupDetailsProvider = FutureProvider.autoDispose.family<ReadingGroupDetails, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getGroupDetails(id);
});

// ── Advanced Feature Providers ──────────────────

final groupProgressProvider = FutureProvider.autoDispose.family<GroupProgressData, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getGroupProgress(id);
});

final groupLeaderboardProvider = FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getGroupLeaderboard(id);
});

final groupStatsProvider = FutureProvider.autoDispose.family<GroupStats, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getGroupStats(id);
});

final groupActivityProvider = FutureProvider.autoDispose.family<List<GroupActivity>, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getGroupActivity(id);
});

final groupProposalsProvider = FutureProvider.autoDispose.family<List<BookProposal>, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getProposals(id);
});

final groupMilestonesProvider = FutureProvider.autoDispose.family<List<ReadingMilestone>, String>((ref, id) {
  return ref.watch(groupsRepositoryProvider).getMilestones(id);
});
