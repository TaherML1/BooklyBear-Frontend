import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/user/data/profile_repository.dart';
import '../features/social/data/friends_repository.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  ConsumerState<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  void _sendRequest(String username) async {
    try {
      await ref.read(friendsRepositoryProvider).sendFriendRequest(username);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      ref.invalidate(publicProfileProvider(username));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _blockUser(String userId) async {
    try {
      await ref.read(friendsRepositoryProvider).blockUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User blocked.')));
      ref.invalidate(publicProfileProvider(widget.username));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.username));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final int currentLevel = user.level;
          final int nextLevelXp = ((currentLevel + 1) * (currentLevel + 1) * 50);
          final int currentLevelXp = (currentLevel * currentLevel * 50);
          final int xpProgress = (user.points - currentLevelXp).clamp(0, nextLevelXp - currentLevelXp);
          final int xpNeeded = nextLevelXp - currentLevelXp;
          final double xpPercent = xpNeeded > 0 ? (xpProgress / xpNeeded).clamp(0.0, 1.0) : 0.0;

          final friendshipAsync = ref.watch(friendshipStatusProvider(user.id));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text(user.displayName, style: Theme.of(context).textTheme.headlineLarge)),
              Center(child: Text('@${user.username}', style: Theme.of(context).textTheme.bodyMedium)),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(child: Text(user.bio!, style: Theme.of(context).textTheme.bodySmall)),
              ],
              const SizedBox(height: 24),
              
              friendshipAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading friendship status')),
                data: (friendship) {
                  if (friendship.status == 'none') {
                    return FilledButton.icon(
                      onPressed: () => _sendRequest(user.username),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Friend'),
                    );
                  } else if (friendship.status == 'PENDING') {
                    return const OutlinedButton(onPressed: null, child: Text('Request Sent'));
                  } else if (friendship.status == 'ACCEPTED') {
                    return const OutlinedButton(onPressed: null, child: Text('Friends'));
                  } else if (friendship.status == 'BLOCKED') {
                    return const OutlinedButton(onPressed: null, child: Text('Blocked'));
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _blockUser(user.id),
                icon: const Icon(Icons.block, color: Colors.red),
                label: const Text('Block User', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Level $currentLevel', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: xpPercent),
                      const SizedBox(height: 8),
                      Text('$xpProgress / $xpNeeded XP'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
