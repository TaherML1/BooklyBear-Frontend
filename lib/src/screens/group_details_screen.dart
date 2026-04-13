import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/groups/data/groups_repository.dart';
import '../features/user/data/profile_repository.dart';
import '../features/groups/domain/group_features.dart';
import '../features/groups/domain/reading_group.dart';
import '../theme/app_theme.dart';
import 'group_widgets.dart';
import 'group_dialogs.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  bool _isActionLoading = false;

  void _joinGroup() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(groupsRepositoryProvider).joinGroup(widget.groupId);
      ref.invalidate(groupDetailsProvider(widget.groupId));
      ref.invalidate(myGroupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _leaveGroup() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(groupsRepositoryProvider).leaveGroup(widget.groupId);
      ref.invalidate(groupDetailsProvider(widget.groupId));
      ref.invalidate(myGroupsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Left group.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(groupDetailsProvider(widget.groupId));
    final myProfileAsync = ref.watch(myProfileProvider);

    return detailsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $err'))),
      data: (group) {
        final myId = myProfileAsync.valueOrNull?.id;
        final myMemberInfo = group.members.where((m) => m.user.id == myId).firstOrNull;
        final isMember = myMemberInfo != null;
        final isAdmin = myMemberInfo?.role == 'admin';

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(group.name, style: Theme.of(context).textTheme.headlineMedium),
              actions: [
                if (isMember)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'leave', child: Text('Leave Group')),
                    ],
                    onSelected: (val) {
                      if (val == 'leave') _leaveGroup();
                    },
                  ),
              ],
              bottom: const TabBar(
                isScrollable: false,
                tabs: [
                  Tab(text: 'Progress'),
                  Tab(text: 'Feed'),
                  Tab(text: 'Voting'),
                  Tab(text: 'Schedule'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ProgressTab(groupId: widget.groupId, group: group, isMember: isMember),
                _ActivityTab(groupId: widget.groupId),
                _VotingTab(groupId: widget.groupId, isAdmin: isAdmin, isMember: isMember),
                _ScheduleTab(groupId: widget.groupId, isAdmin: isAdmin, isMember: isMember),
              ],
            ),
            floatingActionButton: !isMember
                ? Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: FloatingActionButton.extended(
                      onPressed: _isActionLoading ? null : _joinGroup,
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.onPrimary,
                      elevation: 0,
                      icon: const Icon(Icons.group_add),
                      label: Text('Join Club', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ─── Progress Tab ──────────────────────────────────────────────────────────
class _ProgressTab extends ConsumerWidget {
  final String groupId;
  final ReadingGroupDetails group;
  final bool isMember;

  const _ProgressTab({required this.groupId, required this.group, required this.isMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(groupProgressProvider(groupId));
    final statsAsync = ref.watch(groupStatsProvider(groupId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Current Book Card
        if (group.currentBookId != null)
          progressAsync.when(
            data: (data) => _CurrentBookHeader(book: data.currentBook),
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Text('Failed to load current book'),
          )
        else
          _NoBookHeader(isMember: isMember),

        const SizedBox(height: 24),
        
        // Stats Row
        statsAsync.when(
          data: (stats) => _StatsRow(stats: stats),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 32),
        
        // Progress List
        Text('Member Progress', style: GoogleFonts.notoSerif(
          fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.onSurface,
        )),
        const SizedBox(height: 16),
        progressAsync.when(
          data: (data) => Column(
            children: data.members.map((m) => MemberProgressCard(progress: m)).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading progress: $err'),
        ),
      ],
    );
  }
}

class _CurrentBookHeader extends StatelessWidget {
  final Map<String, dynamic>? book;
  const _CurrentBookHeader({this.book});

  @override
  Widget build(BuildContext context) {
    if (book == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryFixed.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              book!['thumbnail'] ?? '',
              width: 70,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70, height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.book, color: AppTheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'CURRENTLY READING',
                    style: GoogleFonts.inter(
                      color: AppTheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book!['title'] ?? 'Unknown',
                  style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${book!['pageCount']} pages total',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBookHeader extends StatelessWidget {
  final bool isMember;
  const _NoBookHeader({required this.isMember});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_stories_outlined, size: 40, color: AppTheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'No book selected yet',
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Go to the Voting tab to propose one!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final GroupStats stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total Pages', value: '${stats.totalPagesRead}'),
          _StatItem(label: 'Finished', value: '${stats.booksFinished}'),
          _StatItem(label: 'Hours', value: '${stats.totalHours}'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSerif(
            fontSize: 22,
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 11)),
      ],
    );
  }
}

// ─── Activity Tab ──────────────────────────────────────────────────────────
class _ActivityTab extends ConsumerWidget {
  final String groupId;
  const _ActivityTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(groupActivityProvider(groupId));

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.forum_outlined, size: 64, color: AppTheme.outlineVariant),
                const SizedBox(height: 12),
                Text('No activity yet.', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) => ActivityItem(activity: activities[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// ─── Voting Tab ────────────────────────────────────────────────────────────
class _VotingTab extends ConsumerWidget {
  final String groupId;
  final bool isAdmin;
  final bool isMember;

  const _VotingTab({required this.groupId, required this.isAdmin, required this.isMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(groupProposalsProvider(groupId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Book Proposals', style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.onSurface,
            )),
            if (isMember)
              TextButton.icon(
                onPressed: () {
                    showDialog(
                      context: context, 
                      builder: (context) => ProposeBookDialog(groupId: groupId)
                    );
                },
                icon: const Icon(Icons.add),
                label: const Text('Propose'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        proposalsAsync.when(
          data: (proposals) => proposals.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No active proposals. Start one!',
                      style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: proposals.map((p) => ProposalCard(
                    proposal: p,
                    isAdmin: isAdmin,
                    onVote: () async {
                      if (p.hasVoted) {
                        await ref.read(groupsRepositoryProvider).removeVote(groupId, p.id);
                      } else {
                        await ref.read(groupsRepositoryProvider).voteForProposal(groupId, p.id);
                      }
                      ref.invalidate(groupProposalsProvider(groupId));
                    },
                    onSelect: () async {
                        await ref.read(groupsRepositoryProvider).selectProposal(groupId, p.id);
                        ref.invalidate(groupProgressProvider(groupId));
                        ref.invalidate(groupProposalsProvider(groupId));
                        ref.invalidate(groupDetailsProvider(groupId));
                    },
                  )).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }
}

// ─── Schedule Tab ──────────────────────────────────────────────────────────
class _ScheduleTab extends ConsumerWidget {
  final String groupId;
  final bool isAdmin;
  final bool isMember;

  const _ScheduleTab({required this.groupId, required this.isAdmin, required this.isMember});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(groupMilestonesProvider(groupId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reading Schedule', style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.onSurface,
            )),
            if (isAdmin)
              IconButton(
                onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => CreateMilestoneDialog(groupId: groupId),
                    );
                },
                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
              ),
          ],
        ),
        const SizedBox(height: 16),
        milestonesAsync.when(
          data: (milestones) => milestones.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No milestones set.',
                      style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: milestones.map((m) => MilestoneItem(milestone: m)).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }
}
