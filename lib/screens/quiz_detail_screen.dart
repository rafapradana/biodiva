import 'dart:convert';
import 'dart:io';
import 'package:biodiva/constants/app_strings.dart';
import 'package:biodiva/models/identification_model.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:biodiva/providers/quiz_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class QuizDetailScreen extends StatefulWidget {
  final String quizId;

  const QuizDetailScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  int _selectedOptionIndex = -1;
  bool _isAnswered = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.startQuiz(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, _) {
        try {
          final quiz = quizProvider.quizzes.firstWhere(
            (q) => q.id == widget.quizId,
            orElse: () {
              debugPrint('Quiz dengan ID ${widget.quizId} tidak ditemukan di daftar quiz');
              debugPrint('Jumlah quiz yang tersedia: ${quizProvider.quizzes.length}');
              if (quizProvider.quizzes.isNotEmpty) {
                debugPrint('IDs quiz yang tersedia: ${quizProvider.quizzes.map((q) => q.id).join(', ')}');
              }
              // Gunakan getCurrentQuiz sebagai fallback jika tersedia
              final currentQuiz = quizProvider.currentQuiz;
              if (currentQuiz != null) {
                debugPrint('Menggunakan current quiz sebagai fallback dengan ID: ${currentQuiz.id}');
                return currentQuiz;
              }
              throw Exception('Quiz tidak ditemukan');
            },
          );
          
          // Dapatkan identifikasi terkait
          final identificationProvider = Provider.of<IdentificationProvider>(context, listen: false);
          final identification = identificationProvider.getIdentificationById(quiz.identificationId);
          
          return Scaffold(
            appBar: AppBar(
              title: Text(quiz.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/quiz'),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (identification != null) ...[
                    // Gambar spesies
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _buildImage(identification),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Nama spesies
                    Text(
                      identification.commonName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      identification.scientificName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                  
                  // Jumlah pertanyaan
                  Text(
                    '${quiz.questions.length} Pertanyaan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Riwayat percobaan
                  if (quiz.attempts != null && quiz.attempts!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Riwayat Percobaan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildAttemptList(context, quiz),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Tombol mulai quiz
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        quizProvider.startQuiz(widget.quizId);
                        context.go('/quiz/play/${widget.quizId}');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        quiz.attempts != null && quiz.attempts!.isNotEmpty
                            ? 'Coba Quiz Lagi'
                            : AppStrings.startQuiz,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tombol kembali ke beranda
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: const Text(
                        'Kembali ke Beranda',
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
        } catch (e) {
          debugPrint('QuizDetail: Exception saat memuat detail quiz: $e');
          return Scaffold(
            appBar: AppBar(
              title: Text('Error'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/quiz'),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan saat memuat detail quiz. Silakan coba lagi nanti.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/quiz'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: const Text(
                        'Kembali ke Daftar Quiz',
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
        }
      },
    );
  }

  Widget _buildAttemptList(BuildContext context, QuizModel quiz) {
    final attempts = quiz.attempts ?? [];
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attempts.length,
      itemBuilder: (context, index) {
        final attempt = attempts[index];
        final score = attempt.score;
        final totalQuestions = attempt.totalQuestions;
        final percentage = totalQuestions > 0 
            ? (score / totalQuestions * 100).toInt()
            : 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getScoreColor(percentage),
                  ),
                  child: Center(
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Percobaan ke-${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Skor: $score/$totalQuestions',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildImage(IdentificationModel identification) {
    // Untuk web dan path spesial, gunakan placeholder
    if (kIsWeb && identification.imageUrl.startsWith('web_image_')) {
      debugPrint('QuizDetail: Path gambar web, menggunakan placeholder: ${identification.imageUrl}');
      return _buildPlaceholderImage(identification);
    }
    
    // Path error atau kosong
    if (identification.imageUrl.isEmpty || 
        identification.imageUrl.startsWith('error_image_')) {
      debugPrint('QuizDetail: Path gambar error atau kosong: ${identification.imageUrl}');
      return _buildPlaceholderImage(identification);
    }
    
    // Jika path menunjuk ke assets
    if (identification.imageUrl.startsWith('assets/')) {
      debugPrint('QuizDetail: Path gambar assets: ${identification.imageUrl}');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          identification.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('QuizDetail: Error memuat gambar dari assets: $error');
            return _buildPlaceholderImage(identification);
          },
        ),
      );
    }
    
    // Untuk mobile, gunakan File jika file ada
    try {
      debugPrint('QuizDetail: Mencoba memuat gambar dari path: ${identification.imageUrl}');
      
      final file = File(identification.imageUrl);
      if (file.existsSync()) {
        debugPrint('QuizDetail: File ditemukan, mencoba load gambar');
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('QuizDetail: Error memuat gambar file: $error');
              return _buildPlaceholderImage(identification);
            },
          ),
        );
      } else {
        debugPrint('QuizDetail: File tidak ditemukan: ${identification.imageUrl}');
        return _buildPlaceholderImage(identification);
      }
    } catch (e) {
      debugPrint('QuizDetail: Exception saat memuat gambar: $e');
      return _buildPlaceholderImage(identification);
    }
  }
  
  Widget _buildPlaceholderImage(IdentificationModel identification) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            identification.type == 'flora' ? Icons.local_florist : Icons.pets,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Gambar ${identification.type} - ${identification.commonName}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorImage(IdentificationModel identification) {
    return _buildPlaceholderImage(identification);
  }
} 