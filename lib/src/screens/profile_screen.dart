import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import this
import '../features/auth/presentation/auth_controller.dart';
import 'package:booklybear/src/features/user/data/profile_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(myProfileProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to Edit Profile Screen
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: profileAsyncValue.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                children: [
                  // Use CachedNetworkImage for the Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.brown[100],
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.brown)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@${user.username}',
                        style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Bio ---
              if (user.bio != null && user.bio!.isNotEmpty)
                Text(
                  user.bio!,
                  style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
                ),
              const SizedBox(height: 24),

              // --- Gamification Stats ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(title: 'Level', value: user.level.toString()),
                  _StatItem(title: 'Points', value: user.points.toString()),
                  _StatItem(title: 'Streak', value: user.currentStreak.toString()),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // --- User Info Section ---
              _InfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: user.email,
              ),
              const SizedBox(height: 16),
              _InfoTile(
                icon: Icons.badge_outlined,
                title: 'User ID',
                subtitle: user.id,
              ),
              
              const SizedBox(height: 40), // More space
              
              // --- Logout Button ---
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.brown)),
      ),
    );
  }
}

// Helper widget for displaying info
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.brown[300]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.black87)),
    );
  }
}

// Helper widget for stats like Level, Points
class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.brown),
        ),
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}