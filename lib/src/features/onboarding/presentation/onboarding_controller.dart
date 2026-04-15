import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/onboarding_repository.dart';
import '../domain/onboarding_models.dart';
import '../../auth/presentation/auth_state_provider.dart';
import '../../../utils/app_logger.dart';

/// Holds all the accumulated quiz state across the multi-step onboarding
class OnboardingQuizState {
  final int currentStep;
  final List<String> selectedGenres;
  final Map<String, int> bookRatings; // isbn -> rating (1-5)
  final String readingPace;
  final String preferredPageRange;
  final String readingFrequency;
  final String dailyReadingTime;
  final String? currentlyReadingIsbn;
  final ReaderArchetype? assignedArchetype;
  final bool isSubmitting;
  final bool isComplete;
  final String? error;

  const OnboardingQuizState({
    this.currentStep = 0,
    this.selectedGenres = const [],
    this.bookRatings = const {},
    this.readingPace = '',
    this.preferredPageRange = '',
    this.readingFrequency = '',
    this.dailyReadingTime = '',
    this.currentlyReadingIsbn,
    this.assignedArchetype,
    this.isSubmitting = false,
    this.isComplete = false,
    this.error,
  });

  OnboardingQuizState copyWith({
    int? currentStep,
    List<String>? selectedGenres,
    Map<String, int>? bookRatings,
    String? readingPace,
    String? preferredPageRange,
    String? readingFrequency,
    String? dailyReadingTime,
    String? currentlyReadingIsbn,
    ReaderArchetype? assignedArchetype,
    bool? isSubmitting,
    bool? isComplete,
    String? error,
  }) {
    return OnboardingQuizState(
      currentStep: currentStep ?? this.currentStep,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      bookRatings: bookRatings ?? this.bookRatings,
      readingPace: readingPace ?? this.readingPace,
      preferredPageRange: preferredPageRange ?? this.preferredPageRange,
      readingFrequency: readingFrequency ?? this.readingFrequency,
      dailyReadingTime: dailyReadingTime ?? this.dailyReadingTime,
      currentlyReadingIsbn: currentlyReadingIsbn ?? this.currentlyReadingIsbn,
      assignedArchetype: assignedArchetype ?? this.assignedArchetype,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isComplete: isComplete ?? this.isComplete,
      error: error,
    );
  }

  /// Total number of steps in the onboarding quiz
  static const int totalSteps = 4;
}

class OnboardingController extends StateNotifier<OnboardingQuizState> {
  final OnboardingRepository _repository;

  OnboardingController(this._repository) : super(const OnboardingQuizState());

  void nextStep() {
    if (state.currentStep < OnboardingQuizState.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // ─── Step 1: Genre Selection ───────────────────────────────────────────
  void toggleGenre(String genre) {
    final genres = List<String>.from(state.selectedGenres);
    if (genres.contains(genre)) {
      genres.remove(genre);
    } else {
      genres.add(genre);
    }
    state = state.copyWith(selectedGenres: genres);
  }

  bool get canProceedFromStep1 => state.selectedGenres.length >= 2;

  // ─── Step 2: Book Selection ────────────────────────────────────────────
  void setBookRating(String isbn, int rating) {
    final ratings = Map<String, int>.from(state.bookRatings);
    ratings[isbn] = rating;
    state = state.copyWith(bookRatings: ratings);
  }

  void removeBookRating(String isbn) {
    final ratings = Map<String, int>.from(state.bookRatings);
    ratings.remove(isbn);
    state = state.copyWith(bookRatings: ratings);
  }

  bool get canProceedFromStep2 => state.bookRatings.length >= 3;

  // ─── Step 3: Reading Habits ────────────────────────────────────────────
  void setReadingPace(String pace) {
    state = state.copyWith(readingPace: pace);
  }

  void setPreferredPageRange(String range) {
    state = state.copyWith(preferredPageRange: range);
  }

  void setReadingFrequency(String freq) {
    state = state.copyWith(readingFrequency: freq);
  }

  void setDailyReadingTime(String time) {
    state = state.copyWith(dailyReadingTime: time);
  }

  void setCurrentlyReadingIsbn(String? isbn) {
    state = state.copyWith(currentlyReadingIsbn: isbn);
  }

  bool get canProceedFromStep3 =>
      state.readingPace.isNotEmpty &&
      state.preferredPageRange.isNotEmpty &&
      state.readingFrequency.isNotEmpty &&
      state.dailyReadingTime.isNotEmpty;

  // ─── Step 4: Submit ────────────────────────────────────────────────────
  Future<bool> submitOnboarding() async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final result = await _repository.submitOnboarding(
        selectedGenres: state.selectedGenres,
        bookRatings: state.bookRatings,
        readingPace: state.readingPace,
        preferredPageRange: state.preferredPageRange,
        readingFrequency: state.readingFrequency,
        dailyReadingTime: state.dailyReadingTime,
        currentlyReadingIsbn: state.currentlyReadingIsbn,
      );

      ReaderArchetype? archetype;
      if (result['archetype'] != null) {
        archetype = ReaderArchetype.fromJson(
          Map<String, dynamic>.from(result['archetype']),
        );
      }

      state = state.copyWith(
        isSubmitting: false,
        isComplete: true,
        assignedArchetype: archetype,
      );

      AppLogger.info('[Onboarding] Completed — Archetype: ${archetype?.key}');
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      AppLogger.error('[Onboarding] Submission error: $e');
      return false;
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingQuizState>((ref) {
  return OnboardingController(ref.read(onboardingRepositoryProvider));
});

/// Checks if the user needs onboarding (used by the router)
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState != AuthState.authenticated) return false;

  try {
    final repo = ref.read(onboardingRepositoryProvider);
    final status = await repo.getOnboardingStatus();
    return status['completed'] == true;
  } catch (e) {
    AppLogger.error('[Onboarding] Status check failed: $e');
    return true; // Assume completed on error to not block the user
  }
});

/// Fetches popular books for the quiz (depends on selected genres)
final popularBooksProvider = FutureProvider.family<List<Map<String, dynamic>>, List<String>>((ref, genres) async {
  final repo = ref.read(onboardingRepositoryProvider);
  return repo.getPopularBooks(genres: genres.isNotEmpty ? genres : null);
});
