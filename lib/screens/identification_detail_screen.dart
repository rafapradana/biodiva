import 'dart:convert';
import 'dart:io';
import 'package:biodiva/constants/app_strings.dart';
import 'package:biodiva/models/identification_model.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:biodiva/providers/quiz_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

class IdentificationDetailScreen extends StatelessWidget {
  final String identificationId;

  const IdentificationDetailScreen({
    super.key,
    required this.identificationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.identificationResult),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/identifier'),
        ),
      ),
      body: Consumer<IdentificationProvider>(
        builder: (context, provider, _) {
          final identification = provider.getIdentificationById(identificationId);
          
          if (identification == null) {
            return const Center(
              child: Text('Identifikasi tidak ditemukan'),
            );
          }
          
          return DetailContent(identification: identification);
        },
      ),
    );
  }
}

class DetailContent extends StatelessWidget {
  final IdentificationModel identification;

  const DetailContent({
    super.key,
    required this.identification,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildImage(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Jenis (Flora/Fauna)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: identification.type == 'flora' ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              identification.type.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nama Umum & Ilmiah
          Text(
            identification.commonName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
          
          const SizedBox(height: 16),
          
          // Tingkat Keyakinan
          _buildConfidenceIndicator(context, identification.confidenceLevel),
          
          const SizedBox(height: 24),
          
          // Deskripsi
          _buildInfoSection(
            context,
            AppStrings.description,
            identification.description,
          ),
          
          const SizedBox(height: 16),
          
          // Habitat
          _buildInfoSection(
            context,
            AppStrings.habitat,
            identification.habitat,
          ),
          
          const SizedBox(height: 24),
          
          // Tabel Klasifikasi
          _buildClassificationTable(context, identification.taxonomy),
          
          const SizedBox(height: 24),
          
          // Status Konservasi
          _buildConservationStatus(context, identification.conservationStatus),
          
          const SizedBox(height: 32),
          
          // Tombol Generate Quiz
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: identification.hasQuiz
                    ? () => _viewExistingQuiz(context, identification.id)
                    : () => _generateQuiz(context, identification.id),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  identification.hasQuiz
                      ? 'Lihat Quiz'
                      : AppStrings.generateQuiz,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tombol Kembali ke Beranda
          Center(
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Untuk web dan path spesial, gunakan placeholder
    if (kIsWeb && identification.imageUrl.startsWith('web_image_')) {
      debugPrint('Path gambar web, menggunakan placeholder: ${identification.imageUrl}');
      return _buildPlaceholderImage();
    }
    
    // Path error atau kosong
    if (identification.imageUrl.isEmpty || 
        identification.imageUrl.startsWith('error_image_')) {
      debugPrint('Path gambar error atau kosong: ${identification.imageUrl}');
      return _buildPlaceholderImage();
    }
    
    // Jika path menunjuk ke assets
    if (identification.imageUrl.startsWith('assets/')) {
      debugPrint('Path gambar assets: ${identification.imageUrl}');
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          identification.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error memuat gambar dari assets: $error');
            return _buildPlaceholderImage();
          },
        ),
      );
    }
    
    // Untuk mobile, gunakan File jika file ada
    try {
      debugPrint('Mencoba memuat gambar dari path: ${identification.imageUrl}');
      
      final file = File(identification.imageUrl);
      if (file.existsSync()) {
        debugPrint('File ditemukan, mencoba load gambar');
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error memuat gambar file: $error');
              return _buildPlaceholderImage();
            },
          ),
        );
      } else {
        debugPrint('File tidak ditemukan: ${identification.imageUrl}');
        return _buildPlaceholderImage();
      }
    } catch (e) {
      debugPrint('Exception saat memuat gambar: $e');
      return _buildPlaceholderImage();
    }
  }
  
  Widget _buildPlaceholderImage() {
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
  
  Widget _buildErrorImage() {
    return _buildPlaceholderImage();
  }

  Widget _buildConfidenceIndicator(BuildContext context, double confidence) {
    final percentage = (confidence * 100).toInt();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.confidenceLevel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearPercentIndicator(
                percent: confidence,
                lineHeight: 20.0,
                animation: true,
                animationDuration: 1000,
                backgroundColor: Colors.grey[300],
                progressColor: _getConfidenceColor(confidence),
                barRadius: const Radius.circular(16),
                padding: const EdgeInsets.symmetric(horizontal: 0),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.lightGreen;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInfoSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildClassificationTable(BuildContext context, Map<String, String> taxonomy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.classification,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          children: taxonomy.entries.map((entry) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConservationStatus(BuildContext context, String status) {
    Color statusColor;
    
    switch (status.toLowerCase()) {
      case 'least concern':
      case 'lc':
        statusColor = Colors.green;
        break;
      case 'near threatened':
      case 'nt':
        statusColor = Colors.lightGreen;
        break;
      case 'vulnerable':
      case 'vu':
        statusColor = Colors.amber;
        break;
      case 'endangered':
      case 'en':
        statusColor = Colors.orange;
        break;
      case 'critically endangered':
      case 'cr':
        statusColor = Colors.red;
        break;
      case 'extinct in the wild':
      case 'ew':
        statusColor = Colors.redAccent;
        break;
      case 'extinct':
      case 'ex':
        statusColor = Colors.black;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.conservationStatus,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  void _generateQuiz(BuildContext context, String identificationId) async {
    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final identificationProvider = Provider.of<IdentificationProvider>(context, listen: false);
      
      // Tampilkan loading
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      // Generate quiz
      final quizId = await quizProvider.generateQuiz(
        identificationId,
        identificationProvider: identificationProvider,
      );
      
      // Update status hasQuiz di identification
      await identificationProvider.updateHasQuiz(identificationId, true);
      
      // Log untuk debugging
      debugPrint('Quiz berhasil dibuat dengan ID: $quizId');
      
      // Pastikan quiz ada di daftar quizzes provider
      final isQuizInProvider = quizProvider.quizzes.any((q) => q.id == quizId);
      debugPrint('Quiz ada di provider: $isQuizInProvider');
      
      // Tutup dialog loading dan navigasi ke quiz
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog
        
        // Pastikan current quiz diset sebelum navigasi
        quizProvider.setCurrentQuiz(quizId);
        
        // Di web, harus ada delay kecil untuk memastikan state provider terupdate
        if (kIsWeb) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        if (context.mounted) {
          context.go('/quiz/detail/$quizId'); // Navigasi ke detail quiz
        }
      }
    } catch (e) {
      // Tutup dialog loading dan tampilkan error
      debugPrint('Error saat membuat quiz: $e');
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
  void _viewExistingQuiz(BuildContext context, String identificationId) async {
    try {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      
      // Dapatkan ID quiz yang sudah dibuat
      final quizId = quizProvider.getQuizIdByIdentificationId(identificationId);
      
      if (quizId != null && context.mounted) {
        // Inisialisasi quiz sebelum navigasi
        quizProvider.setCurrentQuiz(quizId);
        context.go('/quiz/detail/$quizId');
      } else {
        // Jika tidak ditemukan, update status hasQuiz
        final identificationProvider = 
          Provider.of<IdentificationProvider>(context, listen: false);
        await identificationProvider.updateHasQuiz(identificationId, false);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz tidak ditemukan, silakan buat baru')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saat melihat quiz: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat quiz: ${e.toString()}')),
        );
      }
    }
  }
}