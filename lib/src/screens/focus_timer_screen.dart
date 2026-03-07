import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/library/data/library_repository.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/gamification/presentation/gamification_providers.dart';

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
      await ref.read(libraryRepositoryProvider).logReadingSession(
            userBookId: widget.userBookId,
            pagesRead: _pagesRead,
            minutesSpent: _selectedMinutes,
          );
      // Invalidate gamification so XP + streak refresh automatically
      ref.invalidate(gamificationStatusProvider);
      ref.invalidate(libraryProvider);

      if (mounted) {
        Navigator.of(context).pop(true); // true = session was logged
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $e'), backgroundColor: Colors.red),
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
      backgroundColor: const Color(0xFF1A1A2E), // deep calm dark blue
      body: SafeArea(
        child: _finished ? _buildCompletionView() : _buildTimerView(),
      ),
    );
  }

  // ── Active Timer View ─────────────────────────────────────────────────────
  Widget _buildTimerView() {
    return Column(
      children: [
        // ── Top bar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              Text(
                widget.bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              const SizedBox(width: 48), // balance the close button
            ],
          ),
        ),

        const Spacer(),

        // ── Duration picker (only visible when not running) ────────────────
        if (!_running)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _durations.map((d) {
                final selected = d.minutes == _selectedMinutes;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(d.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedMinutes = d.minutes;
                        _resetToSelected();
                      });
                    },
                    selectedColor: const Color(0xFF7B61FF),
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _running ? 'Focus Mode' : 'Ready',
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // ── Play / Pause button ────────────────────────────────────────────
        GestureDetector(
          onTap: _startPause,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B61FF), Color(0xFF5A45FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Reset link ────────────────────────────────────────────────────
        TextButton(
          onPressed: () => setState(_resetToSelected),
          child: const Text('Reset', style: TextStyle(color: Colors.white38)),
        ),

        const Spacer(),

        // ── Motivational quote ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '"A reader lives a thousand lives before he dies."',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ── Completion / Session Log View ─────────────────────────────────────────
  Widget _buildCompletionView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 52, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Session Complete! 🎉',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Great job reading for $_selectedMinutes minutes!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 40),

          // ── Pages read input ─────────────────────────────────────────────
          const Text(
            'How many pages did you read?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
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
                  style: const TextStyle(
                    color: Colors.white,
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
            child: FilledButton.icon(
              onPressed: _loggingSession ? null : _logAndClose,
              icon: _loggingSession
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Log Session & Earn XP', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Skip logging option
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip logging', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

// ─── Arc Progress Painter ─────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final bool running;

  _ArcPainter({required this.progress, required this.running});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF7B61FF), Color(0xFF00C6FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
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
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
