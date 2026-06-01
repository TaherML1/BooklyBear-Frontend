import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/library/data/library_repository.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/gamification/presentation/gamification_providers.dart';
import '../theme/app_theme.dart';

// ─── Timer durations a user can pick ────────────────────────────────────────
const _durations = [
  (label: '5 min', minutes: 5),
  (label: '10 min', minutes: 10),
  (label: '20 min', minutes: 20),
  (label: '30 min', minutes: 30),
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class FocusTimerScreen extends ConsumerStatefulWidget {
  /// The userBookId we'll log the session against when the timer completes.
  final String userBookId;
  final String bookTitle;

  const FocusTimerScreen({
    super.key,
    required this.userBookId,
    required this.bookTitle,
  });

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with TickerProviderStateMixin {
  // ── Timer state ─────────────────────────────────────────────────────────
  int _selectedMinutes = 20;
  late int _totalSeconds;
  int _remainingSeconds = 0;
  Timer? _ticker;
  bool _running = false;
  bool _finished = false;

  // ── Page input (shown on the completion screen) ─────────────────────────
  int _pagesRead = 0;
  bool _loggingSession = false;
  int? _xpEarned;

  // ── Arc animation ────────────────────────────────────────────────────────
  late AnimationController _arcController;

  @override
  void initState() {
    super.initState();
    // Must initialize _arcController FIRST since _resetToSelected uses it
    _arcController = AnimationController(vsync: this, duration: Duration.zero);
    _resetToSelected();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _arcController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _resetToSelected() {
    _totalSeconds = _selectedMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _running = false;
    _finished = false;
    _ticker?.cancel();
    _arcController.value = 0;
  }

  String get _timeLabel {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress =>
      _totalSeconds > 0 ? 1 - (_remainingSeconds / _totalSeconds) : 0;

  void _startPause() {
    if (_finished) return;
    setState(() => _running = !_running);

    if (_running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remainingSeconds <= 1) {
          _ticker?.cancel();
          setState(() {
            _remainingSeconds = 0;
            _running = false;
            _finished = true;
          });
        } else {
          setState(() {
            _remainingSeconds--;
            _arcController.value = _progress;
          });
        }
      });
    } else {
      _ticker?.cancel();
    }
  }

  Future<void> _logAndClose() async {
    setState(() => _loggingSession = true);
    try {
      final response = await ref.read(libraryRepositoryProvider).logReadingSession(
            userBookId: widget.userBookId,
            pagesRead: _pagesRead,
            minutesSpent: _selectedMinutes,
          );
      
      final xp = response['xpEarned'] as int? ?? 0;
      setState(() => _xpEarned = xp);
      // Invalidate gamification so XP + streak refresh automatically
      ref.invalidate(gamificationStatusProvider);
      ref.invalidate(libraryProvider);

      if (mounted) {
        // Wait a brief moment so the user sees the XP earned before popping
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(true); // true = session was logged
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingSession = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary, // deep scholarly green
      body: SafeArea(
        child: _finished ? _buildCompletionView() : _buildTimerView(),
      ),
    );
  }

  // ── Active Timer View — Scholarly Zen ──────────────────────────────────
  Widget _buildTimerView() {
    return Column(
      children: [
        // ── Top bar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.primaryFixedDim.withAlpha(180)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  widget.bookTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerif(
                    color: AppTheme.primaryFixedDim.withAlpha(180),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48), // balance the close button
            ],
          ),
        ),

        const Spacer(),

        // ── Session Description ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Deep Reading Session.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              color: AppTheme.primaryFixedDim,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Immerse yourself in the narrative. Your progress is being archived.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.primaryFixedDim.withAlpha(140),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Duration picker (only visible when not running) ────────────────
        if (!_running)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Wrap(
              alignment: WrapAlignment.center,
              children: _durations.map((d) {
                final selected = d.minutes == _selectedMinutes;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(d.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedMinutes = d.minutes;
                        _resetToSelected();
                      });
                    },
                    selectedColor: AppTheme.primaryFixed,
                    backgroundColor: AppTheme.primaryContainer,
                    labelStyle: GoogleFonts.inter(
                      color: selected ? AppTheme.onPrimaryFixed : AppTheme.primaryFixedDim.withAlpha(160),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: const StadiumBorder(),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 32),

        // ── Arc + countdown ────────────────────────────────────────────────
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background arc
              CustomPaint(
                size: const Size(260, 260),
                painter: _ArcPainter(progress: _progress, running: _running),
              ),
              // Time label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeLabel,
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryFixedDim,
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _running ? 'Focus Mode' : 'Ready',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryFixedDim.withAlpha(100),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // ── Play / Pause button — editorial green gradient ─────────────
        GestureDetector(
          onTap: _startPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.primaryFixed, AppTheme.primaryFixedDim],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryFixedDim.withAlpha(80),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppTheme.onPrimaryFixed,
              size: 42,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Reset link ────────────────────────────────────────────────────
        TextButton(
          onPressed: () => setState(_resetToSelected),
          child: Text('Reset', style: GoogleFonts.inter(color: AppTheme.primaryFixedDim.withAlpha(100))),
        ),

        const Spacer(),

        // ── Motivational quote — serif italic ─────────────────────────────
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '"A reader lives a thousand lives before he dies."',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              color: AppTheme.primaryFixedDim.withAlpha(80),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ── Completion / Session Log View — Editorial Celebration ──────────────
  Widget _buildCompletionView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy — warm gold accent
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFD4A84B), Color(0xFFB8923F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A84B).withAlpha(80),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Session Complete!',
            style: GoogleFonts.notoSerif(
              color: AppTheme.primaryFixedDim,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _xpEarned != null 
              ? 'You focused for $_selectedMinutes minutes of deep reading. +$_xpEarned XP earned.'
              : 'You focused for $_selectedMinutes minutes of deep reading. Ready to log your session?',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.primaryFixedDim.withAlpha(140),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),

          // ── Pages read input ─────────────────────────────────────────────
          Text(
            'How many pages did you read?',
            style: GoogleFonts.inter(
              color: AppTheme.primaryFixedDim.withAlpha(200),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageButton(
                icon: Icons.remove,
                onTap: () => setState(() { if (_pagesRead > 0) _pagesRead--; }),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 80,
                child: Text(
                  '$_pagesRead',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.primaryFixedDim,
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              _PageButton(
                icon: Icons.add,
                onTap: () => setState(() => _pagesRead++),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // ── Log Session button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryFixed, AppTheme.primaryFixedDim],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: FilledButton.icon(
                onPressed: _loggingSession ? null : _logAndClose,
                icon: _loggingSession
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimaryFixed),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  'Log Session & Earn XP',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.onPrimaryFixed,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip logging option
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Skip logging',
              style: GoogleFonts.inter(color: AppTheme.primaryFixedDim.withAlpha(100)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arc Progress Painter — Editorial Green ───────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final bool running;

  _ArcPainter({required this.progress, required this.running});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Track — subtle
    final trackPaint = Paint()
      ..color = AppTheme.primaryContainer.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc — green gradient
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.primaryFixed, AppTheme.primaryFixedDim],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at top
      2 * math.pi * progress, // sweep
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.running != running;
}

// ─── +/- Page Button ─────────────────────────────────────────────────────────
class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PageButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryFixedDim.withAlpha(30)),
        ),
        child: Icon(icon, color: AppTheme.primaryFixedDim, size: 26),
      ),
    );
  }
}
