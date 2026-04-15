import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

    return AlertDialog(
      title: Text('Propose a Book', style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: libraryAsync.when(
          data: (userBooks) {
            if (userBooks.isEmpty) {
              return Center(
                child: Text(
                  'Add some books to your library first!',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: userBooks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ub = userBooks[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        ub.book.coverImageUrl,
                        width: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.book, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                    title: Text(
                      ub.book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(ub.book.author, style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant)),
        ),
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
    return AlertDialog(
      title: Text('Add Reading Goal', style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
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
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text('Deadline', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 13),
                ),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant)),
        ),
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
                    if (context.mounted) {
                      ref.invalidate(groupMilestonesProvider(widget.groupId));
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
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
