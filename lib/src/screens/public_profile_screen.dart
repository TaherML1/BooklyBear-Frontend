// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/user/data/profile_repository.dart';
import '../features/social/data/friends_repository.dart';
import '../theme/app_theme.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  void _sendRequest(String username) async {
    try {
      await ref.read(friendsRepositoryProvider).sendFriendRequest(username);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
      ref.invalidate(publicProfileProvider(username));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _blockUser(String userId) async {
    try {
      await ref.read(friendsRepositoryProvider).blockUser(userId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User blocked.')));
      ref.invalidate(publicProfileProvider(widget.username));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          final int nextLevelXp =
              ((currentLevel + 1) * (currentLevel + 1) * 50);
          final int currentLevelXp = (currentLevel * currentLevel * 50);
          final int xpProgress = (user.points - currentLevelXp).clamp(
            0,
            nextLevelXp - currentLevelXp,
          );
          final int xpNeeded = nextLevelXp - currentLevelXp;
          final double xpPercent = xpNeeded > 0
              ? (xpProgress / xpNeeded).clamp(0.0, 1.0)
              : 0.0;

          final friendshipAsync = ref.watch(friendshipStatusProvider(user.id));

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primaryFixed,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.notoSerif(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onPrimaryFixed,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Center(
                child: Text(
                  '@${user.username}',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    user.bio!,
                    style: GoogleFonts.inter(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 28),

              friendshipAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text(
                    'Error loading friendship status',
                    style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                  ),
                ),
                data: (friendship) {
                  if (friendship.status == 'none') {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: FilledButton.icon(
                        onPressed: () => _sendRequest(user.username),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Friend'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    );
                  } else if (friendship.status == 'PENDING') {
                    return const OutlinedButton(
                      onPressed: null,
                      child: Text('Request Sent'),
                    );
                  } else if (friendship.status == 'ACCEPTED') {
                    return OutlinedButton(
                      onPressed: null,
                      child: Text(
                        'Friends ✓',
                        style: GoogleFonts.inter(color: AppTheme.primary),
                      ),
                    );
                  } else if (friendship.status == 'BLOCKED') {
                    return const OutlinedButton(
                      onPressed: null,
                      child: Text('Blocked'),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _blockUser(user.id),
                icon: const Icon(Icons.block, color: AppTheme.error),
                label: Text(
                  'Block User',
                  style: GoogleFonts.inter(color: AppTheme.error),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Level $currentLevel',
                        style: GoogleFonts.inter(
                          color: AppTheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: xpPercent,
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$xpProgress / $xpNeeded XP',
                      style: GoogleFonts.inter(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
