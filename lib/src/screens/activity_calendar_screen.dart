import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../features/gamification/domain/reading_session.dart';
import '../features/library/presentation/library_providers.dart';
import '../theme/app_theme.dart';

class ActivityCalendarScreen extends ConsumerStatefulWidget {
  const ActivityCalendarScreen({super.key});

  @override
  ConsumerState<ActivityCalendarScreen> createState() => _ActivityCalendarScreenState();
}

class _ActivityCalendarScreenState extends ConsumerState<ActivityCalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDate;

  // Normalize date to ignore time
  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(DateTime.now());
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(readingHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Journey'),
        backgroundColor: Colors.transparent,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading history: $err')),
        data: (sessions) {
          // Process data
          final Map<DateTime, List<ReadingSession>> sessionsByDate = {};
          int totalPages = 0;
          int booksFinished = 0;

          for (final s in sessions) {
            final date = _normalizeDate(s.sessionDate);
            if (!sessionsByDate.containsKey(date)) {
              sessionsByDate[date] = [];
            }
            sessionsByDate[date]!.add(s);
            
            totalPages += s.pagesRead;
            if (s.endPage != null && s.endPage! >= s.userBook.book.pageCount) {
              booksFinished++;
            }
          }

          final selectedSessions = _selectedDate != null ? (sessionsByDate[_selectedDate] ?? []) : [];

          return CustomScrollView(
            slivers: [
              // Overall Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Pages',
                          value: totalPages.toString(),
                          icon: Icons.menu_book,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Books Finished',
                          value: booksFinished.toString(),
                          icon: Icons.emoji_events,
                          color: const Color(0xFFD4A84B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar Heatmap Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              // Calendar Heatmap Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildCalendarGrid(sessionsByDate),
                ),
              ),

              // Selected Day Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    _selectedDate != null 
                        ? DateFormat('EEEE, MMM d').format(_selectedDate!)
                        : 'Select a day',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ),

              if (selectedSessions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "No reading activity on this day. Take a breath!",
                      style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = selectedSessions[index];
                      final isFinished = s.endPage != null && s.endPage! >= s.userBook.book.pageCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryFixed,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(isFinished ? Icons.emoji_events : Icons.menu_book, color: AppTheme.onPrimaryFixed),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.userBook.book.title,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isFinished ? 'Finished the book!' : 'Read ${s.pagesRead} pages',
                                      style: GoogleFonts.inter(
                                        color: isFinished ? const Color(0xFFD4A84B) : AppTheme.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: selectedSessions.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<ReadingSession>> sessionsByDate) {
    // Determine days in month
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOffset = _currentMonth.weekday % 7; // Sunday = 0

    final List<Widget> dayWidgets = [];

    // Header row (Sun, Mon...)
    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final day in weekDays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.outlineVariant,
            ),
          ),
        ),
      );
    }

    // Empty spaces for first week
    for (int i = 0; i < firstDayOffset; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days of the month
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      final isSelected = _selectedDate == date;
      
      final sessions = sessionsByDate[date] ?? [];
      final pagesRead = sessions.fold<int>(0, (sum, s) => sum + s.pagesRead);

      // Determine heatmap color based on real-world reading habits
      Color cellColor = AppTheme.surfaceContainerHighest.withAlpha(80);
      if (pagesRead > 0) {
        if (pagesRead <= 15) {
          // Light reading session (1-15 pages)
          cellColor = AppTheme.primaryFixed.withAlpha(60);
        } else if (pagesRead <= 35) {
          // Moderate session (16-35 pages)
          cellColor = AppTheme.primaryFixed.withAlpha(120);
        } else if (pagesRead <= 75) {
          // Heavy session (36-75 pages)
          cellColor = AppTheme.primaryFixed.withAlpha(180);
        } else {
          // Power reading! (76+ pages)
          cellColor = AppTheme.primaryFixed;
        }
      }

      dayWidgets.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(color: AppTheme.onSurface, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: pagesRead >= 36 ? AppTheme.onPrimaryFixed : AppTheme.onSurface,
                  ),
                ),
                if (pagesRead > 0)
                  Text(
                    '${pagesRead}p',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: pagesRead >= 36 
                          ? AppTheme.onPrimaryFixed.withAlpha(200) 
                          : AppTheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
