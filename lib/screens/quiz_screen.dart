import 'package:biodiva/constants/app_strings.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:biodiva/providers/quiz_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    
    // Inisialisasi provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).init();
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    final provider = Provider.of<QuizProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.quizTitle),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: AppStrings.quizListTab),
            Tab(text: AppStrings.quizHistoryTab),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari quiz...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Filter',
                  onSelected: (value) {
                    Provider.of<QuizProvider>(context, listen: false)
                        .setFilter(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'all',
                      child: Text(AppStrings.filterAll),
                    ),
                    const PopupMenuItem(
                      value: 'flora',
                      child: Text(AppStrings.filterFlora),
                    ),
                    const PopupMenuItem(
                      value: 'fauna',
                      child: Text(AppStrings.filterFauna),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
        children: [
          _buildQuizTab(),
          _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuizTab() {
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
    return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        final quizzes = provider.quizzes;
        
        if (quizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.noQuizzes,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Identifikasi flora atau fauna untuk membuat quiz',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/identifier'),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Identifikasi Sekarang'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizzes.length,
          itemBuilder: (context, index) {
            final quiz = quizzes[index];
            return _buildQuizCard(context, quiz);
          },
        );
      },
    );
  }
  
  Widget _buildHistoryTab() {
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        final quizAttempts = provider.quizAttempts;
        
        if (quizAttempts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum Ada Riwayat Quiz',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ambil quiz untuk melihat riwayat',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quizAttempts.length,
          itemBuilder: (context, index) {
            final quiz = quizAttempts[index];
            return _buildQuizHistoryCard(context, quiz);
          },
        );
      },
    );
  }
  
  Widget _buildQuizCard(BuildContext context, QuizModel quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/quiz/detail/${quiz.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: quiz.type == 'flora' ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  quiz.type.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Title
              Text(
                quiz.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Info
              Row(
                children: [
                  const Icon(
                    Icons.question_answer,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quiz.questions.length} pertanyaan',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM yyyy').format(quiz.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Mulai quiz
                    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                    quizProvider.startQuiz(quiz.id);
                    context.go('/quiz/play/${quiz.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(AppStrings.startQuiz),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuizHistoryCard(BuildContext context, QuizModel quiz) {
    // Ambil attempt terakhir
    final lastAttempt = quiz.attempts?.isNotEmpty == true 
        ? quiz.attempts!.last 
        : null;
    
    if (lastAttempt == null) return const SizedBox.shrink();
    
    final score = lastAttempt.score;
    final total = lastAttempt.totalQuestions;
    final percentage = total > 0 ? (score / total * 100).toInt() : 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/quiz/result/${quiz.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                quiz.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Score
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getScoreColor(percentage),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.quizScore}$score/$total',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${AppStrings.quizDate}${DateFormat('dd MMM yyyy').format(lastAttempt.attemptDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/quiz/result/${quiz.id}'),
                      child: const Text(AppStrings.quizDetails),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Mulai quiz lagi
                        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
                        quizProvider.startQuiz(quiz.id);
                        context.go('/quiz/play/${quiz.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(AppStrings.startQuiz),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.lightGreen;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
} 