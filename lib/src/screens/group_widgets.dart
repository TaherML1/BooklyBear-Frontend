import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/groups/domain/group_features.dart';
import '../theme/app_theme.dart';

// ─── Progress Item (Member Progress Bar) ───────────────────────────────────
class MemberProgressCard extends StatelessWidget {
  final MemberProgress progress;
  const MemberProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryFixed,
                  backgroundImage: progress.avatarUrl != null ? NetworkImage(progress.avatarUrl!) : null,
                  child: progress.avatarUrl == null
                      ? Text(
                          progress.displayName[0].toUpperCase(),
                          style: GoogleFonts.notoSerif(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onPrimaryFixed,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progress.displayName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Text(
                  '${progress.percentage}%',
                  style: GoogleFonts.inter(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress.percentage / 100,
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${progress.currentPage} / ${progress.totalPages} pages',
              style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
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
      case ActivityType.pagesRead: return Icons.menu_book_rounded;
      case ActivityType.bookFinished: return Icons.workspace_premium_rounded;
      case ActivityType.memberJoined: return Icons.person_add_rounded;
      case ActivityType.memberLeft: return Icons.person_remove_rounded;
      case ActivityType.bookSelected: return Icons.auto_stories_rounded;
      case ActivityType.milestoneCreated: return Icons.flag_rounded;
      case ActivityType.voteCast: return Icons.how_to_vote_rounded;
      case ActivityType.bookProposed: return Icons.lightbulb_outline_rounded;
    }
  }

  String _getMessage() {
    final user = activity.user.displayName;
    final meta = activity.metadata;
    switch (activity.type) {
      case ActivityType.pagesRead:
        return '$user read ${meta['pagesRead']} pages of "${meta['bookTitle']}"';
      case ActivityType.bookFinished:
        return '$user finished "${meta['bookTitle']}"';
      case ActivityType.memberJoined:
        return '$user joined the club';
      case ActivityType.memberLeft:
        return '$user left the club';
      case ActivityType.bookSelected:
        return 'The group selected "${meta['bookTitle']}" to read next';
      case ActivityType.milestoneCreated:
        return 'New milestone: "${meta['title']}" by ${meta['targetPage']} pages';
      case ActivityType.voteCast:
        return '$user voted for a book';
      case ActivityType.bookProposed:
        return '$user proposed "${meta['bookTitle']}"';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryFixed.withAlpha(60),
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
                  style: GoogleFonts.inter(color: AppTheme.onSurface, height: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(activity.createdAt),
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12),
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
    final book = proposal.book;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              book['thumbnail'] ?? '',
              width: 50,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 75,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.book, color: AppTheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Unknown',
                  style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Proposed by ${proposal.proposedBy['displayName']}',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.how_to_vote, size: 14, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${proposal.voteCount} votes',
                      style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12),
                    ),
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
                  color: proposal.hasVoted ? AppTheme.error : AppTheme.outlineVariant,
                ),
                onPressed: onVote,
              ),
              if (isAdmin && onSelect != null)
                TextButton(
                  onPressed: onSelect,
                  child: Text('Select', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Icon(
            milestone.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: milestone.isCompleted
                ? AppTheme.primary
                : (milestone.isOverdue ? AppTheme.error : AppTheme.outlineVariant),
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(milestone.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  'Goal: ${milestone.targetPage} pages • Due: ${_formatDate(milestone.deadline)}',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          if (milestone.isOverdue && !milestone.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Overdue',
                style: GoogleFonts.inter(
                  color: AppTheme.onErrorContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
