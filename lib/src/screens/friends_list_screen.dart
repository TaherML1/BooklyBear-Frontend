import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/social/data/friends_repository.dart';
import '../theme/app_theme.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends', style: Theme.of(context).textTheme.headlineMedium),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Friends'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyFriends(context, ref),
          _buildRequests(context, ref),
        ],
      ),
    );
  }

  Widget _buildMyFriends(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(myFriendsProvider);

    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant))),
      data: (friends) {
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 64, color: AppTheme.outlineVariant),
                const SizedBox(height: 12),
                Text('No friends yet.', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 15)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final f = friends[index];
            return Container(
              decoration: AppTheme.cardDecoration,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryFixed,
                  backgroundImage: f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
                  child: f.avatarUrl == null
                      ? Text(f.displayName[0].toUpperCase(), style: GoogleFonts.notoSerif(color: AppTheme.onPrimaryFixed, fontWeight: FontWeight.w600))
                      : null,
                ),
                title: Text(f.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('@${f.username}', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove_outlined),
                  color: AppTheme.error,
                  onPressed: () async {
                    await ref.read(friendsRepositoryProvider).removeFriend(f.friendshipId);
                    ref.invalidate(myFriendsProvider);
                  },
                ),
                onTap: () => context.push('/profile/${f.username}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequests(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant))),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline, size: 64, color: AppTheme.outlineVariant),
                const SizedBox(height: 12),
                Text('No pending requests.', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 15)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = requests[index];
            return Container(
              decoration: AppTheme.cardDecoration,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryFixed,
                  backgroundImage: r.requester.avatarUrl != null ? NetworkImage(r.requester.avatarUrl!) : null,
                  child: r.requester.avatarUrl == null
                      ? Text(r.requester.displayName[0].toUpperCase(), style: GoogleFonts.notoSerif(color: AppTheme.onPrimaryFixed, fontWeight: FontWeight.w600))
                      : null,
                ),
                title: Text(r.requester.displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('@${r.requester.username} wants to be friends', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: AppTheme.primary),
                      onPressed: () async {
                        await ref.read(friendsRepositoryProvider).acceptRequest(r.id);
                        ref.invalidate(pendingRequestsProvider);
                        ref.invalidate(myFriendsProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                      onPressed: () async {
                        await ref.read(friendsRepositoryProvider).rejectRequest(r.id);
                        ref.invalidate(pendingRequestsProvider);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
