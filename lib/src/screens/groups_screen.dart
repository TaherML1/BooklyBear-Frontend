import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/groups/data/groups_repository.dart';
import '../theme/app_theme.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> with SingleTickerProviderStateMixin {
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
        title: Text('Reading Clubs', style: Theme.of(context).textTheme.headlineMedium),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Clubs'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroups(context, ref),
          _buildDiscoverGroups(context, ref),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(32),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.push('/groups/create');
          },
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimary,
          elevation: 0,
          icon: const Icon(Icons.add),
          label: Text('Create Club', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildMyGroups(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant))),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_outlined, size: 64, color: AppTheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'You haven\'t joined any clubs yet.',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Discover clubs to join!',
                  style: GoogleFonts.inter(color: AppTheme.outline, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = groups[index];
            return _GroupCard(
              name: group.name,
              subtitle: '${group.memberCount} members',
              onTap: () => context.push('/groups/${group.id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscoverGroups(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant))),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_outlined, size: 64, color: AppTheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'No clubs available to discover.',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 15),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = groups[index];
            return _GroupCard(
              name: group.name,
              subtitle: group.description ?? 'No description',
              onTap: () => context.push('/groups/${group.id}'),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
            );
          },
        );
      },
    );
  }
}

// ─── Group Card ───────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _GroupCard({
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryFixed,
                child: const Icon(Icons.group, color: AppTheme.onPrimaryFixed, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
