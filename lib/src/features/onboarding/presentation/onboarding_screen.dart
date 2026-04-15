import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../domain/onboarding_models.dart';
import 'onboarding_controller.dart';
import '../../../routing/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Listen for step changes to animate the PageView
    ref.listen(onboardingControllerProvider, (prev, next) {
      if (prev?.currentStep != next.currentStep) {
        _goToStep(next.currentStep);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress Bar ──────────────────────────────────────
            if (!quizState.isComplete)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (quizState.currentStep > 0)
                          GestureDetector(
                            onTap: controller.previousStep,
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.onSurfaceVariant,
                              size: 22,
                            ),
                          )
                        else
                          const SizedBox(width: 22),
                        Text(
                          'Step ${quizState.currentStep + 1} of ${OnboardingQuizState.totalSteps}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 22),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end:
                            (quizState.currentStep + 1) /
                            OnboardingQuizState.totalSteps,
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor: AppTheme.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // ── Page Content ──────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GenreSelectionStep(controller: controller, state: quizState),
                  _BookPickerStep(controller: controller, state: quizState),
                  _ReadingHabitsStep(controller: controller, state: quizState),
                  _AnalyzingRevealStep(
                    controller: controller,
                    state: quizState,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1: Genre Selection
// ═══════════════════════════════════════════════════════════════════════════════

class _GenreSelectionStep extends StatelessWidget {
  final OnboardingController controller;
  final OnboardingQuizState state;
  const _GenreSelectionStep({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What worlds\ncall to you?',
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick at least 2 genres you love.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: availableGenres.length,
              itemBuilder: (context, index) {
                final genre = availableGenres[index];
                final isSelected = state.selectedGenres.contains(genre.key);
                return _GenreTile(
                  genre: genre,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    controller.toggleGenre(genre.key);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _NextButton(
            label: 'Continue',
            enabled: controller.canProceedFromStep1,
            onTap: controller.nextStep,
          ),
        ],
      ),
    );
  }
}

class _GenreTile extends StatelessWidget {
  final GenreOption genre;
  final bool isSelected;
  final VoidCallback onTap;
  const _GenreTile({
    required this.genre,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryFixed
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(genre.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              genre.displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.onPrimaryFixed
                    : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2: Book Picker
// ═══════════════════════════════════════════════════════════════════════════════

class _BookPickerStep extends ConsumerWidget {
  final OnboardingController controller;
  final OnboardingQuizState state;
  const _BookPickerStep({required this.controller, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(popularBooksProvider(state.selectedGenres));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Have you read\nany of these?',
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap books you\'ve read and rate them. (At least 3)',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load books: $err',
                  style: GoogleFonts.inter(color: AppTheme.error),
                ),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Text(
                      'No books found. Try different genres.',
                      style: GoogleFonts.inter(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.5,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final isbn = book['isbn'] as String? ?? '';
                    final rating = state.bookRatings[isbn];
                    return _BookCard(
                      title: book['title'] as String? ?? 'Unknown',
                      coverUrl: book['coverImageUrl'] as String? ?? '',
                      author: book['author'] as String? ?? '',
                      rating: rating,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (rating != null) {
                          controller.removeBookRating(isbn);
                        } else {
                          controller.setBookRating(isbn, 4); // Default 4 stars
                        }
                      },
                      onRatingChanged: (r) => controller.setBookRating(isbn, r),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _NextButton(
            label: 'Continue (${state.bookRatings.length} rated)',
            enabled: controller.canProceedFromStep2,
            onTap: controller.nextStep,
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final String title;
  final String coverUrl;
  final String author;
  final int? rating;
  final VoidCallback onTap;
  final ValueChanged<int> onRatingChanged;

  const _BookCard({
    required this.title,
    required this.coverUrl,
    required this.author,
    required this.rating,
    required this.onTap,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = rating != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cover
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: AppTheme.primary, width: 2.5)
                    : null,
                boxShadow: isSelected ? AppTheme.ambientShadow : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverUrl.isNotEmpty
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.surfaceContainerHigh,
                              child: const Icon(
                                Icons.book,
                                size: 32,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.surfaceContainerHigh,
                            child: const Icon(
                              Icons.book,
                              size: 32,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                    if (isSelected)
                      Container(
                        color: AppTheme.primary.withAlpha(40),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          // Star rating if selected
          if (isSelected) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => onRatingChanged(i + 1),
                  child: Icon(
                    i < (rating ?? 0)
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.primary,
                    size: 16,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3: Reading Habits
// ═══════════════════════════════════════════════════════════════════════════════

class _ReadingHabitsStep extends StatelessWidget {
  final OnboardingController controller;
  final OnboardingQuizState state;
  const _ReadingHabitsStep({required this.controller, required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do\nyou read?',
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us understand your reading style.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _HabitSection(
                  title: '📖 Reading Pace',
                  options: paceOptions,
                  selectedKey: state.readingPace,
                  onSelect: controller.setReadingPace,
                ),
                const SizedBox(height: 20),
                _HabitSection(
                  title: '📅 How Often Do You Read?',
                  options: frequencyOptions,
                  selectedKey: state.readingFrequency,
                  onSelect: controller.setReadingFrequency,
                ),
                const SizedBox(height: 20),
                _HabitSection(
                  title: '⏱️ Daily Reading Time',
                  options: dailyTimeOptions,
                  selectedKey: state.dailyReadingTime,
                  onSelect: controller.setDailyReadingTime,
                ),
                const SizedBox(height: 20),
                _HabitSection(
                  title: '📚 Preferred Book Length',
                  options: pageRangeOptions,
                  selectedKey: state.preferredPageRange,
                  onSelect: controller.setPreferredPageRange,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _NextButton(
            label: 'Analyze My Taste',
            enabled: controller.canProceedFromStep3,
            onTap: controller.nextStep,
          ),
        ],
      ),
    );
  }
}

class _HabitSection extends StatelessWidget {
  final String title;
  final List<HabitOption> options;
  final String selectedKey;
  final ValueChanged<String> onSelect;

  const _HabitSection({
    required this.title,
    required this.options,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        ...options.map((opt) {
          final isSelected = selectedKey == opt.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(opt.key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryFixed
                      : AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppTheme.primary, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppTheme.onSurface,
                            ),
                          ),
                          if (opt.subtitle.isNotEmpty)
                            Text(
                              opt.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 4: Analyzing & Archetype Reveal
// ═══════════════════════════════════════════════════════════════════════════════

class _AnalyzingRevealStep extends ConsumerStatefulWidget {
  final OnboardingController controller;
  final OnboardingQuizState state;
  const _AnalyzingRevealStep({required this.controller, required this.state});

  @override
  ConsumerState<_AnalyzingRevealStep> createState() =>
      _AnalyzingRevealStepState();
}

class _AnalyzingRevealStepState extends ConsumerState<_AnalyzingRevealStep>
    with TickerProviderStateMixin {
  bool _isAnalyzing = true;
  late AnimationController _pulseController;
  late AnimationController _revealController;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
    _revealOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _revealController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    // Submit the quiz
    final success = await widget.controller.submitOnboarding();

    // Show the analyzing animation for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() => _isAnalyzing = false);
      _pulseController.stop();
      _revealController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(onboardingControllerProvider);

    if (_isAnalyzing) {
      return _buildAnalyzingView();
    }

    if (quizState.assignedArchetype != null) {
      return _buildRevealView(quizState.assignedArchetype!);
    }

    // Error state
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text(
            quizState.error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _NextButton(
            label: 'Try Again',
            enabled: true,
            onTap: () {
              setState(() => _isAnalyzing = true);
              _startAnalysis();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + (_pulseController.value * 0.2),
                child: child,
              );
            },
            child: const Text('🐻', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 28),
          Text(
            'Analyzing your taste...',
            style: GoogleFonts.notoSerif(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BooklyBear is reading between the lines.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealView(ReaderArchetype archetype) {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        return Opacity(
          opacity: _revealOpacity.value,
          child: Transform.scale(
            scale: _revealScale.value,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Archetype Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.ambientShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          archetype.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'You are...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          archetype.displayName,
                          style: GoogleFonts.notoSerif(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: archetype.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          archetype.tagline,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          archetype.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.onSurface,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This will shape your recommendations.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'You can change it anytime from your Profile.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _NextButton(
                    label: 'Start Reading →',
                    enabled: true,
                    onTap: () {
                      // Mark onboarding as done in the router state
                      ref.read(onboardingCompletedProvider.notifier).state =
                          true;
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared: Next Button
// ═══════════════════════════════════════════════════════════════════════════════

class _NextButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _NextButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          decoration: BoxDecoration(
            gradient: enabled ? AppTheme.primaryGradient : null,
            color: enabled ? null : AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(32),
          ),
          child: FilledButton(
            onPressed: enabled ? onTap : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
