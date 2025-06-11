import 'package:biodiva/constants/app_strings.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:biodiva/providers/quiz_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

class QuizPlayScreen extends StatefulWidget {
  final String quizId;
  
  const QuizPlayScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        final currentQuiz = quizProvider.currentQuiz;
        final currentQuestionIndex = quizProvider.currentQuestionIndex;
        
        if (currentQuiz == null) {
          return const Scaffold(
            body: Center(
              child: Text('Quiz tidak ditemukan'),
            ),
          );
        }
        
        final currentQuestion = currentQuiz.questions[currentQuestionIndex];
        final isLastQuestion = currentQuestionIndex == currentQuiz.questions.length - 1;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('Quiz - ${currentQuiz.title}'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmation(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      Text(
                        'Pertanyaan ${currentQuestionIndex + 1}/${currentQuiz.questions.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearPercentIndicator(
                          percent: (currentQuestionIndex + 1) / currentQuiz.questions.length,
                          lineHeight: 10,
                          backgroundColor: Colors.grey[300],
                          progressColor: Theme.of(context).primaryColor,
                          barRadius: const Radius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Question
                  Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion.options.length,
                      itemBuilder: (context, index) {
                        final option = currentQuestion.options[index];
                        final isCorrect = index == currentQuestion.correctOptionIndex;
                        
                        Color? optionColor;
                        if (_isAnswered) {
                          if (index == _selectedOptionIndex && isCorrect) {
                            optionColor = Colors.green[100];
                          } else if (index == _selectedOptionIndex && !isCorrect) {
                            optionColor = Colors.red[100];
                          } else if (isCorrect) {
                            optionColor = Colors.green[50];
                          }
                        }
                        
                        Color? borderColor;
                        if (_isAnswered) {
                          if (isCorrect) {
                            borderColor = Colors.green;
                          } else if (index == _selectedOptionIndex) {
                            borderColor = Colors.red;
                          }
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: optionColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: borderColor ?? Colors.transparent,
                              width: borderColor != null ? 2 : 0,
                            ),
                          ),
                          child: InkWell(
                            onTap: _isAnswered ? null : () => _selectOption(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedOptionIndex == index
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                      color: _selectedOptionIndex == index
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                    ),
                                    child: _selectedOptionIndex == index
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (_isAnswered && isCorrect)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  else if (_isAnswered && index == _selectedOptionIndex && !isCorrect)
                                    const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Explanation (when answered)
                  if (_isAnswered && currentQuestion.explanation != null)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Penjelasan:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(currentQuestion.explanation ?? ''),
                          ],
                        ),
                      ),
                    ),
                  
                  // Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isAnswered
                          ? () => _nextQuestion(isLastQuestion)
                          : _selectedOptionIndex != null
                              ? _checkAnswer
                              : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _isAnswered
                            ? isLastQuestion
                                ? AppStrings.finishQuiz
                                : AppStrings.nextQuestion
                            : 'Jawab',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
    });
  }
  
  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;
    
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.answerQuestion(_selectedOptionIndex!);
    
    setState(() {
      _isAnswered = true;
    });
  }
  
  void _nextQuestion(bool isLastQuestion) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    
    if (isLastQuestion) {
      // Selesaikan quiz
      quizProvider.finishQuiz().then((_) {
        if (context.mounted) {
          final quizId = quizProvider.currentQuiz?.id;
          if (quizId != null) {
            context.go('/quiz/result/$quizId');
          } else {
            context.go('/quiz');
          }
        }
      });
    } else {
      // Pindah ke pertanyaan berikutnya
      quizProvider.nextQuestion();
      
      setState(() {
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    }
  }
  
  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Quiz?'),
        content: const Text('Anda yakin ingin keluar? Progres quiz tidak akan disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/quiz');
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 