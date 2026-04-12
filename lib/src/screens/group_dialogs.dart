import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/groups/data/groups_repository.dart';
import '../features/library/presentation/library_providers.dart';
import '../theme/app_theme.dart';

// ─── Propose Book Dialog ───────────────────────────────────────────────────
class ProposeBookDialog extends ConsumerWidget {
  final String groupId;
  const ProposeBookDialog({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Propose a Book'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: libraryAsync.when(
          data: (userBooks) {
            if (userBooks.isEmpty) {
              return const Center(child: Text('Add some books to your library first!'));
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: userBooks.length,
              itemBuilder: (context, index) {
                final ub = userBooks[index];
                return ListTile(
                  leading: Image.network(
                    ub.book.coverImageUrl,
                    width: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.book),
                  ),
                  title: Text(ub.book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(ub.book.author),
                  onTap: () async {
                    try {
                      await ref.read(groupsRepositoryProvider).proposeBook(groupId, ub.book.id);
                      if (context.mounted) {
                        ref.invalidate(groupProposalsProvider(groupId));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Book proposed!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }
}

// ─── Create Milestone Dialog ───────────────────────────────────────────────
class CreateMilestoneDialog extends ConsumerStatefulWidget {
  final String groupId;
  const CreateMilestoneDialog({super.key, required this.groupId});

  @override
  ConsumerState<CreateMilestoneDialog> createState() => _CreateMilestoneDialogState();
}

class _CreateMilestoneDialogState extends ConsumerState<CreateMilestoneDialog> {
  final _titleController = TextEditingController();
  final _pageController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Reading Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g. Chapter 5'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pageController,
              decoration: const InputDecoration(labelText: 'Target Page', hintText: 'e.g. 150'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Deadline'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FilledButton(
                onPressed: () async {
                  if (_titleController.text.isEmpty || _pageController.text.isEmpty) return;
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(groupsRepositoryProvider).createMilestone(
                          widget.groupId,
                          _titleController.text,
                          int.parse(_pageController.text),
                          _selectedDate,
                        );
                    if (mounted) {
                      ref.invalidate(groupMilestonesProvider(widget.groupId));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                child: const Text('Create'),
              ),
      ],
    );
  }
}
