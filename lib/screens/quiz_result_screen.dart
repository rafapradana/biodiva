import 'package:biodiva/constants/app_strings.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:biodiva/providers/quiz_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class QuizResultScreen extends StatelessWidget {
  final String attemptId;

  const QuizResultScreen({
    super.key,
    required this.attemptId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        final quiz = provider.currentQuiz;
        
        if (quiz == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.quizResult),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/quiz'),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Cari attempt berdasarkan ID
        final attempt = quiz.attempts?.firstWhere(
          (a) => a.id == attemptId,
          orElse: () => QuizAttempt(
            id: '',
            score: 0,
            totalQuestions: 0,
            userAnswers: [],
          ),
        );
        
        if (attempt == null || attempt.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.quizResult),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/quiz'),
              ),
            ),
            body: const Center(
              child: Text('Hasil quiz tidak ditemukan'),
            ),
          );
        }
        
        final scorePercentage = attempt.score / attempt.totalQuestions;
        final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(attempt.attemptDate);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.quizResult),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/quiz'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Quiz title
                Text(
                  quiz.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Quiz date
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Score indicator
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 15.0,
                  animation: true,
                  animationDuration: 1500,
                  percent: scorePercentage,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${attempt.score}/${attempt.totalQuestions}',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Skor',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: _getScoreColor(scorePercentage),
                  backgroundColor: Colors.grey[300]!,
                ),
                
                const SizedBox(height: 32),
                
                // Score message
                Text(
                  _getScoreMessage(scorePercentage),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(scorePercentage),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Stats
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow(
                        context,
                        AppStrings.correctAnswers,
                        '${attempt.score}',
                      ),
                      const Divider(),
                      _buildStatRow(
                        context,
                        AppStrings.totalQuestions,
                        '${attempt.totalQuestions}',
                      ),
                      const Divider(),
                      _buildStatRow(
                        context,
                        'Persentase',
                        '${(scorePercentage * 100).toInt()}%',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Answer review
                if (quiz.questions.isNotEmpty)
                  _buildAnswerReview(context, quiz, attempt),
                
                const SizedBox(height: 32),
                
                // Back to quizzes button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/quiz'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      AppStrings.backToQuizzes,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnswerReview(BuildContext context, QuizModel quiz, QuizAttempt attempt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peninjauan Jawaban',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quiz.questions.length,
          itemBuilder: (context, index) {
            final question = quiz.questions[index];
            final userAnswer = attempt.userAnswers[index];
            final isCorrect = userAnswer == question.correctOptionIndex;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isCorrect ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isCorrect ? 'Benar' : 'Salah',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Pertanyaan ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jawaban Anda:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userAnswer >= 0 && userAnswer < question.options.length
                          ? question.options[userAnswer]
                          : 'Tidak dijawab',
                      style: TextStyle(
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jawaban Benar:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.options[question.correctOptionIndex],
                      style: const TextStyle(
                        color: Colors.green,
                      ),
                    ),
                    if (question.explanation != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Penjelasan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(question.explanation!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Color _getScoreColor(double scorePercentage) {
    if (scorePercentage >= 0.8) return Colors.green;
    if (scorePercentage >= 0.6) return Colors.lightGreen;
    if (scorePercentage >= 0.4) return Colors.orange;
    return Colors.red;
  }
  
  String _getScoreMessage(double scorePercentage) {
    if (scorePercentage >= 0.8) {
      return 'Luar Biasa! Kamu Menguasai Materi Ini!';
    } else if (scorePercentage >= 0.6) {
      return 'Bagus! Kamu Hampir Menguasai Materi Ini!';
    } else if (scorePercentage >= 0.4) {
      return 'Lumayan! Terus Belajar Ya!';
    } else {
      return 'Jangan Menyerah! Coba Lagi!';
    }
  }
}