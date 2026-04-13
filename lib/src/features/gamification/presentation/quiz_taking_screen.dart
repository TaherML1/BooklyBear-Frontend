import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/quiz_models.dart';
import '../data/gamification_repository.dart';
import 'gamification_providers.dart';
import '../../../theme/app_theme.dart';

class QuizTakingScreen extends ConsumerStatefulWidget {
  final Quiz quiz;

  const QuizTakingScreen({Key? key, required this.quiz}) : super(key: key);

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  bool _isSubmitting = false;
  late List<QuizQuestion> _selectedQuestions;

  @override
  void initState() {
    super.initState();
    final allQuestions = List<QuizQuestion>.from(widget.quiz.questions);
    allQuestions.shuffle();
    _selectedQuestions = allQuestions.take(10).toList();
  }

  void _submitQuiz() async {
    if (_selectedAnswers.length < _selectedQuestions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build answers array mapped to their unique questionIDs
      List<Map<String, dynamic>> answersPayload = [];
      for (int i = 0; i < _selectedQuestions.length; i++) {
        answersPayload.add({
          'questionId': _selectedQuestions[i].id,
          'answerIndex': _selectedAnswers[i]!,
        });
      }

      final repository = ref.read(gamificationRepositoryProvider);
      final result = await repository.submitQuiz(widget.quiz.id, answersPayload);
      
      // Refresh user's gamification stats/badges after quiz completion
      ref.invalidate(userBadgesProvider);
      ref.invalidate(gamificationStatusProvider);
      
      _showResultDialog(result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showResultDialog(QuizAttemptResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            result.passed ? 'Congratulations! 🎉' : 'Keep Trying!',
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You scored ${result.score}%',
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              if (result.passed) ...[
                Text(
                  'You earned ${result.xpEarned} XP!',
                  style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                ),
                if (result.newlyEarnedBadge != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('🏆 New Badge Unlocked 🏆', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
                        const SizedBox(height: 10),
                        Text(result.newlyEarnedBadge!.icon, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 4),
                        Text(result.newlyEarnedBadge!.name, style: GoogleFonts.notoSerif(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(result.newlyEarnedBadge!.description, textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                ]
              ] else ...[
                Text(
                  'You need at least 70% to pass and earn the rewards. Read up and try again later!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ]
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text('Finish'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: const Center(child: Text('This quiz has no questions.')),
      );
    }
    
    final question = _selectedQuestions[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _selectedQuestions.length,
          ),
        ),
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${_selectedQuestions.length}',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.ambientShadow,
                  ),
                  child: Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(question.options.length, (index) {
                  final isSelected = _selectedAnswers[_currentIndex] == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? AppTheme.primary
                            : AppTheme.outlineVariant.withAlpha(60),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected 
                          ? AppTheme.primaryFixed.withAlpha(100)
                          : Colors.transparent,
                      ),
                      child: RadioListTile<int>(
                        title: Text(question.options[index], style: GoogleFonts.inter()),
                        value: index,
                        groupValue: _selectedAnswers[_currentIndex],
                        activeColor: AppTheme.primary,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnswers[_currentIndex] = value!;
                          });
                        },
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
                      )
                    else 
                      const SizedBox.shrink(),
                    
                    if (_currentIndex < _selectedQuestions.length - 1)
                      FilledButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Next'),
                        onPressed: _selectedAnswers.containsKey(_currentIndex) 
                          ? () {
                              setState(() {
                                _currentIndex++;
                              });
                            }
                          : null,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Submit Quiz'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                          ),
                          onPressed: _selectedAnswers.containsKey(_currentIndex) ? _submitQuiz : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
