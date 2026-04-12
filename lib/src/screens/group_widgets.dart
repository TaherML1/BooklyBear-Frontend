import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/groups/domain/group_features.dart';
import '../theme/app_theme.dart';

// ─── Progress Item (Member Progress Bar) ───────────────────────────────────
class MemberProgressCard extends StatelessWidget {
  final MemberProgress progress;
  const MemberProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: progress.avatarUrl != null ? NetworkImage(progress.avatarUrl!) : null,
                child: progress.avatarUrl == null ? Text(progress.displayName[0].toUpperCase()) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.displayName,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                '${progress.percentage}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percentage / 100,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${progress.currentPage} / ${progress.totalPages} pages',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Item (Timeline Entry) ───────────────────────────────────────
class ActivityItem extends StatelessWidget {
  final GroupActivity activity;
  const ActivityItem({super.key, required this.activity});

  IconData _getIcon() {
    switch (activity.type) {
      case ActivityType.pages_read: return Icons.menu_book_rounded;
      case ActivityType.book_finished: return Icons.workspace_premium_rounded;
      case ActivityType.member_joined: return Icons.person_add_rounded;
      case ActivityType.member_left: return Icons.person_remove_rounded;
      case ActivityType.book_selected: return Icons.auto_stories_rounded;
      case ActivityType.milestone_created: return Icons.flag_rounded;
      case ActivityType.vote_cast: return Icons.how_to_vote_rounded;
      case ActivityType.book_proposed: return Icons.lightbulb_outline_rounded;
    }
  }

  String _getMessage() {
    final user = activity.user.displayName;
    final meta = activity.metadata;
    switch (activity.type) {
      case ActivityType.pages_read:
        return '$user read ${meta['pagesRead']} pages of "${meta['bookTitle']}"';
      case ActivityType.book_finished:
        return '🎉 $user finished "${meta['bookTitle']}"!';
      case ActivityType.member_joined:
        return '$user joined the club';
      case ActivityType.member_left:
        return '$user left the club';
      case ActivityType.book_selected:
        return '📖 Group selected "${meta['bookTitle']}" to read next!';
      case ActivityType.milestone_created:
        return '📅 New milestone: "${meta['title']}" by ${meta['targetPage']} pages';
      case ActivityType.vote_cast:
        return '$user voted for a book';
      case ActivityType.book_proposed:
        return '💡 $user proposed "${meta['bookTitle']}"';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMessage(),
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  _timeAgo(activity.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

// ─── Proposal Card ─────────────────────────────────────────────────────────
class ProposalCard extends StatelessWidget {
  final BookProposal proposal;
  final VoidCallback onVote;
  final VoidCallback? onSelect; // Admin only
  final bool isAdmin;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onVote,
    this.onSelect,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = proposal.book;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                book['thumbnail'] ?? '',
                width: 50,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 50, height: 75, color: Colors.grey.shade200),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book['title'] ?? 'Unknown', style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Proposed by ${proposal.proposedBy['displayName']}', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.how_to_vote, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${proposal.voteCount} votes', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    proposal.hasVoted ? Icons.favorite : Icons.favorite_border,
                    color: proposal.hasVoted ? Colors.red : null,
                  ),
                  onPressed: onVote,
                ),
                if (isAdmin && onSelect != null)
                  TextButton(
                    onPressed: onSelect,
                    child: const Text('Select'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Milestone Item ────────────────────────────────────────────────────────
class MilestoneItem extends StatelessWidget {
  final ReadingMilestone milestone;
  const MilestoneItem({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          milestone.isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: milestone.isCompleted ? Colors.green : (milestone.isOverdue ? Colors.red : Colors.grey),
        ),
        title: Text(milestone.title),
        subtitle: Text('Goal: ${milestone.targetPage} pages • Due: ${_formatDate(milestone.deadline)}'),
        trailing: milestone.isOverdue && !milestone.isCompleted
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Overdue', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
