import 'package:biodiva/models/identification_model.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:biodiva/providers/user_provider.dart';
import 'package:biodiva/services/gemini_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

class QuizProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final List<QuizModel> _quizzes = [];
  QuizModel? _currentQuiz;
  QuizAttempt? _currentAttempt;
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  String? _error;
  
  // Filter
  String _filterType = 'all'; // 'all', 'flora', 'fauna'
  String _searchQuery = '';
  
  // Box name untuk penyimpanan quiz
  static const String _boxName = 'quizzesBox';
  
  // Getters
  List<QuizModel> get quizzes => _getFilteredQuizzes();
  List<QuizModel> get quizAttempts => _quizzes
      .where((quiz) => quiz.attempts != null && quiz.attempts!.isNotEmpty)
      .toList();
  QuizModel? get currentQuiz => _currentQuiz;
  QuizAttempt? get currentAttempt => _currentAttempt;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterType => _filterType;
  String get searchQuery => _searchQuery;
  
  // Inisialisasi provider
  Future<void> init() async {
    final box = Hive.box(_boxName);
    
    // Load data quiz dari Hive
    final quizzesData = box.values.toList();
    _quizzes.clear();
    
    for (final data in quizzesData) {
      if (data is Map) {
        try {
          // Parse questions
          final List<QuizQuestion> questions = [];
          if (data['questions'] is List) {
            for (final q in data['questions']) {
              questions.add(
                QuizQuestion(
                  id: q['id'] ?? '',
                  question: q['question'] ?? '',
                  options: List<String>.from(q['options'] ?? []),
                  correctOptionIndex: q['correctOptionIndex'] ?? 0,
                  explanation: q['explanation'],
                ),
              );
            }
          }
          
          // Parse attempts
          final List<QuizAttempt> attempts = [];
          if (data['attempts'] is List) {
            for (final a in data['attempts']) {
              attempts.add(
                QuizAttempt(
                  id: a['id'] ?? '',
                  score: a['score'] ?? 0,
                  totalQuestions: a['totalQuestions'] ?? 0,
                  userAnswers: List<int>.from(a['userAnswers'] ?? []),
                  attemptDate: a['attemptDate'] != null 
                      ? DateTime.parse(a['attemptDate']) 
                      : DateTime.now(),
                ),
              );
            }
          }
          
          final quiz = QuizModel(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            identificationId: data['identificationId'] ?? '',
            questions: questions,
            type: data['type'] ?? '',
            attempts: attempts,
            createdAt: data['createdAt'] != null 
                ? DateTime.parse(data['createdAt']) 
                : DateTime.now(),
          );
          
          _quizzes.add(quiz);
        } catch (e) {
          debugPrint('Error parsing quiz: $e');
        }
      }
    }
    
    // Sort berdasarkan tanggal terbaru
    _sortQuizzes();
    
    notifyListeners();
  }
  
  // Menghasilkan quiz baru dari identification ID
  Future<String> generateQuiz(String identificationId, {required IdentificationProvider identificationProvider}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      debugPrint('Mulai generate quiz untuk identification ID: $identificationId');
      
      // Cek apakah sudah ada quiz untuk identification ini
      final existingQuizId = getQuizIdByIdentificationId(identificationId);
      if (existingQuizId != null) {
        debugPrint('Quiz sudah ada dengan ID: $existingQuizId');
        
        // Pastikan quiz ada di _quizzes
        final existingQuiz = getQuizById(existingQuizId);
        if (existingQuiz != null) {
          _currentQuiz = existingQuiz;
          _isLoading = false;
          notifyListeners();
          return existingQuizId;
        } else {
          debugPrint('Quiz dengan ID $existingQuizId tidak ditemukan di memori, membuat baru');
        }
      }
      
      // Dapatkan identification dari provider yang diberikan
      final identification = identificationProvider.getIdentificationById(identificationId);
      
      if (identification == null) {
        debugPrint('Identification tidak ditemukan dengan ID: $identificationId');
        throw Exception('Identifikasi tidak ditemukan');
      }
      
      debugPrint('Membuat quiz untuk species: ${identification.commonName}');
      QuizModel? quiz;
      
      try {
        // Coba generate quiz dengan AI
        quiz = await _geminiService.generateQuiz(identification);
        debugPrint('Quiz berhasil dibuat dengan AI');
      } catch (aiError) {
        debugPrint('Error saat generate quiz dengan AI: $aiError');
        // Fallback ke quiz dummy jika AI gagal
        debugPrint('Menggunakan quiz dummy sebagai fallback');
        quiz = _geminiService.createDummyQuiz(identification);
        debugPrint('Quiz dummy berhasil dibuat sebagai fallback');
      }
      
      if (quiz != null) {
        debugPrint('Quiz berhasil dibuat dengan ID: ${quiz.id}');
        
        // Tambahkan ke daftar quiz
        _currentQuiz = quiz;
        _quizzes.add(quiz);
        
        // Increment quiz count in user stats
        try {
          final userBox = Hive.box('userBox');
          final userData = userBox.get('user');
          if (userData is Map) {
            final int quizCount = (userData['quizCount'] ?? 0) + 1;
            await userBox.put('user', {
              ...userData,
              'quizCount': quizCount,
            });
            debugPrint('User stats berhasil diupdate: quizCount = $quizCount');
          }
        } catch (statsError) {
          debugPrint('Error saat update user stats: $statsError');
        }
        
        try {
          // Simpan ke penyimpanan lokal
          final box = Hive.box(_boxName);
          final serializedQuiz = _serializeQuiz(quiz);
          await box.put(quiz.id, serializedQuiz);
          debugPrint('Quiz berhasil disimpan ke Hive dengan ID: ${quiz.id}');
          
          // Verifikasi quiz tersimpan
          final savedQuiz = box.get(quiz.id);
          if (savedQuiz == null) {
            debugPrint('WARNING: Quiz tidak ditemukan di Hive setelah disimpan!');
            // Coba simpan sekali lagi
            await box.put(quiz.id, serializedQuiz);
            final retryCheck = box.get(quiz.id);
            if (retryCheck == null) {
              debugPrint('WARNING: Quiz masih tidak tersimpan setelah percobaan kedua');
            } else {
              debugPrint('Quiz berhasil disimpan pada percobaan kedua');
            }
          } else {
            debugPrint('Quiz terverifikasi tersimpan di Hive');
          }
        } catch (saveError) {
          debugPrint('Error saat menyimpan quiz ke Hive: $saveError');
          // Lanjutkan meskipun penyimpanan gagal
        }
        
        // Sort ulang
        _sortQuizzes();
        
        _isLoading = false;
        notifyListeners();
        return quiz.id;
      } else {
        debugPrint('Quiz null setelah generate');
        // Gunakan quiz dummy sebagai fallback terakhir
        final dummyQuiz = _geminiService.createDummyQuiz(identification);
        _currentQuiz = dummyQuiz;
        _quizzes.add(dummyQuiz);
        
        try {
          final box = Hive.box(_boxName);
          await box.put(dummyQuiz.id, _serializeQuiz(dummyQuiz));
        } catch (e) {
          debugPrint('Error saat menyimpan quiz dummy: $e');
        }
        
        _sortQuizzes();
        _isLoading = false;
        notifyListeners();
        return dummyQuiz.id;
      }
    } catch (e) {
      debugPrint('Error umum saat generate quiz: $e');
      _error = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      throw Exception('Quiz generation error: $e');
    }
  }

  // Menghasilkan quiz baru
  Future<bool> generateQuiz2(
    IdentificationModel identification,
    IdentificationProvider identificationProvider,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final quiz = await _geminiService.generateQuiz(identification);
      
      if (quiz != null) {
        _currentQuiz = quiz;
        _quizzes.add(quiz);
        
        // Update identification hasQuiz
        await identificationProvider.updateHasQuiz(identification.id, true);
        
        // Simpan ke penyimpanan lokal
        final box = Hive.box(_boxName);
        await box.put(quiz.id, _serializeQuiz(quiz));
        
        // Sort ulang
        _sortQuizzes();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Gagal membuat quiz, coba lagi';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Dapatkan ID quiz berdasarkan ID identifikasi
  String? getQuizIdByIdentificationId(String identificationId) {
    try {
      final quiz = _quizzes.firstWhere(
        (quiz) => quiz.identificationId == identificationId,
      );
      return quiz.id;
    } catch (e) {
      return null;
    }
  }
  
  // Mulai quiz baru
  void startQuiz(String quizId) {
    final quiz = _quizzes.firstWhere(
      (quiz) => quiz.id == quizId,
      orElse: () => _quizzes.first,
    );
    
    _currentQuiz = quiz;
    _currentQuestionIndex = 0;
    _currentAttempt = QuizAttempt(
      id: const Uuid().v4(),
      score: 0,
      totalQuestions: quiz.questions.length,
      userAnswers: List.filled(quiz.questions.length, -1),
    );
    
    notifyListeners();
  }
  
  // Jawab pertanyaan
  void answerQuestion(int optionIndex) {
    if (_currentQuiz == null || _currentAttempt == null) return;
    
    // Simpan jawaban
    final userAnswers = List<int>.from(_currentAttempt!.userAnswers);
    userAnswers[_currentQuestionIndex] = optionIndex;
    
    // Hitung skor
    int score = 0;
    for (int i = 0; i < userAnswers.length; i++) {
      if (userAnswers[i] == _currentQuiz!.questions[i].correctOptionIndex) {
        score++;
      }
    }
    
    // Update attempt
    _currentAttempt = QuizAttempt(
      id: _currentAttempt!.id,
      score: score,
      totalQuestions: _currentQuiz!.questions.length,
      userAnswers: userAnswers,
      attemptDate: _currentAttempt!.attemptDate,
    );
    
    notifyListeners();
  }
  
  // Pindah ke pertanyaan berikutnya
  void nextQuestion() {
    if (_currentQuiz == null || _currentAttempt == null) return;
    
    if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }
  
  // Selesaikan quiz
  Future<void> finishQuiz() async {
    if (_currentQuiz == null || _currentAttempt == null) return;
    
    // Update quiz dengan attempt baru
    final attempts = _currentQuiz!.attempts ?? [];
    attempts.add(_currentAttempt!);
    
    final updatedQuiz = _currentQuiz!.copyWith(attempts: attempts);
    
    // Update di list
    final index = _quizzes.indexWhere((q) => q.id == updatedQuiz.id);
    if (index != -1) {
      _quizzes[index] = updatedQuiz;
    }
    
    _currentQuiz = updatedQuiz;
    
    // Simpan ke penyimpanan lokal
    final box = Hive.box(_boxName);
    await box.put(updatedQuiz.id, _serializeQuiz(updatedQuiz));
    
    notifyListeners();
  }
  
  // Set current quiz
  void setCurrentQuiz(String id) {
    _currentQuiz = _quizzes.firstWhere(
      (quiz) => quiz.id == id,
      orElse: () => _quizzes.first,
    );
    notifyListeners();
  }
  
  // Set filter
  void setFilter(String filterType) {
    _filterType = filterType;
    notifyListeners();
  }
  
  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Reset filter
  void resetFilter() {
    _filterType = 'all';
    _searchQuery = '';
    notifyListeners();
  }
  
  // Serialisasi quiz untuk penyimpanan
  Map<String, dynamic> _serializeQuiz(QuizModel quiz) {
    // Serialisasi questions
    final questions = quiz.questions.map((q) => {
      'id': q.id,
      'question': q.question,
      'options': q.options,
      'correctOptionIndex': q.correctOptionIndex,
      'explanation': q.explanation,
    }).toList();
    
    // Serialisasi attempts
    final attempts = quiz.attempts?.map((a) => {
      'id': a.id,
      'score': a.score,
      'totalQuestions': a.totalQuestions,
      'userAnswers': a.userAnswers,
      'attemptDate': a.attemptDate.toIso8601String(),
    }).toList();
    
    return {
      'id': quiz.id,
      'title': quiz.title,
      'identificationId': quiz.identificationId,
      'questions': questions,
      'type': quiz.type,
      'attempts': attempts,
      'createdAt': quiz.createdAt.toIso8601String(),
    };
  }
  
  // Filter quiz berdasarkan kriteria
  List<QuizModel> _getFilteredQuizzes() {
    List<QuizModel> filteredList = List.from(_quizzes);
    
    // Filter berdasarkan tipe
    if (_filterType != 'all') {
      filteredList = filteredList.where((q) => q.type == _filterType).toList();
    }
    
    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((q) {
        final title = q.title.toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return title.contains(query);
      }).toList();
    }
    
    return filteredList;
  }
  
  // Sort quiz
  void _sortQuizzes() {
    _quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  // Dapatkan quiz berdasarkan ID
  QuizModel? getQuizById(String quizId) {
    try {
      return _quizzes.firstWhere((quiz) => quiz.id == quizId);
    } catch (e) {
      debugPrint('Quiz dengan ID $quizId tidak ditemukan');
      return null;
    }
  }
}
