import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'gamification_providers.dart';
import 'quiz_taking_screen.dart';

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(generalQuizzesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Brain Teasers & Quizzes')),
      body: quizzesAsync.when(
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const Center(
              child: Text('No quizzes available at the moment!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      quiz.badgeIcon ?? '❓',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    quiz.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quiz.description),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text('${quiz.xpReward} XP for passing'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizTakingScreen(quiz: quiz),
                        ),
                      );
                    },
                    child: const Text('Take Quiz'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
