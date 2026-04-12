import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/social/data/friends_repository.dart';

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
        title: const Text('Friends'),
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
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (friends) {
        if (friends.isEmpty) return const Center(child: Text('No friends yet.'));
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final f = friends[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
                child: f.avatarUrl == null ? Text(f.displayName[0].toUpperCase()) : null,
              ),
              title: Text(f.displayName),
              subtitle: Text('@${f.username}'),
              trailing: IconButton(
                icon: const Icon(Icons.person_remove),
                color: Colors.red,
                onPressed: () async {
                  await ref.read(friendsRepositoryProvider).removeFriend(f.friendshipId);
                  ref.invalidate(myFriendsProvider);
                },
              ),
              onTap: () => context.push('/profile/${f.username}'),
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
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('No pending requests.'));
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final r = requests[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: r.requester.avatarUrl != null ? NetworkImage(r.requester.avatarUrl!) : null,
                child: r.requester.avatarUrl == null ? Text(r.requester.displayName[0].toUpperCase()) : null,
              ),
              title: Text(r.requester.displayName),
              subtitle: Text('@${r.requester.username} wants to be friends'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      await ref.read(friendsRepositoryProvider).acceptRequest(r.id);
                      ref.invalidate(pendingRequestsProvider);
                      ref.invalidate(myFriendsProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await ref.read(friendsRepositoryProvider).rejectRequest(r.id);
                      ref.invalidate(pendingRequestsProvider);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
