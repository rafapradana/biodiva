import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:biodiva/providers/quiz_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Inisialisasi provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).init();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Quiz'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }
  
  Widget _buildQuizTab() {
    return const Center(
      child: Text('Daftar Quiz - Segera Hadir'),
    );
  }
  
  Widget _buildHistoryTab() {
    return const Center(
      child: Text('Riwayat Quiz - Segera Hadir'),
    );
  }
} 