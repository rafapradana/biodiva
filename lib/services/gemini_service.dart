import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:biodiva/models/identification_model.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class GeminiService {
  // API key diambil dari file .env
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  static const _uuid = Uuid();
  
  // Model Gemini yang digunakan
  static const String _geminiModelName = 'gemini-2.0-flash';
  
  // Instance model Gemini
  late final GenerativeModel _model;
  
  GeminiService() {
    if (_apiKey.isEmpty) {
      debugPrint('PERINGATAN: API key Gemini tidak ditemukan di file .env');
    }
    
    _model = GenerativeModel(
      model: _geminiModelName,
      apiKey: _apiKey,
    );
  }
  
  // Mengidentifikasi flora atau fauna dari gambar (File) - untuk mobile
  Future<IdentificationModel?> identifySpecies(File? imageFile) async {
    try {
      // Jika file null, gunakan dummy data untuk demo
      if (imageFile == null) {
        debugPrint('File gambar null, menggunakan dummy data');
        return _createDummyIdentification();
      }
      
      // Di web, gunakan pendekatan berbeda
      if (kIsWeb) {
        // Untuk web, konversi File ke Uint8List
        final bytes = await imageFile.readAsBytes();
        return identifySpeciesFromBytes(bytes);
      }
      
      debugPrint('Mengidentifikasi gambar dari path: ${imageFile.path}');
      
      // Pertama, salin gambar ke direktori aplikasi untuk penyimpanan permanen
      final permImageFile = await _copyImageToAppDirectory(imageFile);
      debugPrint('File gambar disalin ke lokasi permanen: ${permImageFile.path}');
      
      // Baca gambar sebagai bytes untuk dikirim ke API
      final bytes = await permImageFile.readAsBytes();
      
      // Siapkan prompt untuk AI
      const promptText = '''
      Identifikasi spesies flora atau fauna dalam gambar ini. 
      Berikan hasil identifikasi dalam format JSON dengan struktur berikut:
      {
        "type": "flora" atau "fauna",
        "commonName": "nama umum spesies",
        "scientificName": "nama ilmiah spesies",
        "confidenceLevel": tingkat keyakinan (0-100),
        "description": "deskripsi tentang spesies",
        "habitat": "habitat spesies",
        "taxonomy": {
          "kingdom": "",
          "phylum": "",
          "class": "",
          "order": "",
          "family": "",
          "genus": "",
          "species": ""
        },
        "conservationStatus": "status konservasi"
      }
      ''';
      
      // Buat prompt dan image part
      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', bytes);
      
      // Buat permintaan ke Gemini dengan gambar dan prompt menggunakan Content.multi
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      
      // Dapatkan teks respons
      final responseText = response.text;
      
      if (responseText == null) {
        throw Exception('Response kosong dari Gemini');
      }
      
      // Ekstrak JSON dari respons
      final jsonString = _extractJsonFromText(responseText);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Buat model identifikasi, gunakan path file yang telah disalin
      return IdentificationModel(
        id: _uuid.v4(),
        imageUrl: permImageFile.path,
        type: data['type'] ?? 'unknown',
        commonName: data['commonName'] ?? 'Tidak diketahui',
        scientificName: data['scientificName'] ?? 'Tidak diketahui',
        confidenceLevel: (data['confidenceLevel'] as num?)?.toDouble() != null
            ? ((data['confidenceLevel'] as num).toDouble() / 100) // Konversi dari 0-100 ke 0.0-1.0
            : 0.0,
        description: data['description'] ?? 'Tidak ada deskripsi',
        habitat: data['habitat'] ?? 'Tidak ada data habitat',
        taxonomy: _parseTaxonomy(data['taxonomy']),
        conservationStatus: data['conservationStatus'] ?? 'Tidak diketahui',
      );
    } catch (e) {
      debugPrint('Error saat identifikasi: $e');
      return _createDummyIdentification();
    }
  }
  
  // Fungsi untuk menyalin gambar ke direktori aplikasi dan memastikan file tersimpan
  Future<File> _copyImageToAppDirectory(File originalFile) async {
    try {
      debugPrint('Menyalin gambar dari: ${originalFile.path}');
      if (!await originalFile.exists()) {
        debugPrint('PERINGATAN: File asli tidak ditemukan: ${originalFile.path}');
        throw Exception('File asli tidak ditemukan');
      }

      // Dapatkan direktori aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${appDir.path}/biodiva_images';
      
      // Buat direktori jika belum ada
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Buat nama file unik
      final String fileName = 'image_${_uuid.v4()}${path.extension(originalFile.path)}';
      final String newPath = '$dirPath/$fileName';
      debugPrint('Path penyimpanan baru: $newPath');
      
      // Salin file
      final File newFile = await originalFile.copy(newPath);
      
      // Verifikasi file telah disalin
      if (await newFile.exists()) {
        final fileSize = await newFile.length();
        debugPrint('File berhasil disalin ke: $newPath (ukuran: $fileSize bytes)');
        return newFile;
      } else {
        debugPrint('PERINGATAN: File tidak terdeteksi setelah penyalinan!');
        
        // Coba metode alternatif dengan bytes
        try {
          final bytes = await originalFile.readAsBytes();
          final File altFile = File(newPath);
          await altFile.writeAsBytes(bytes);
          
          if (await altFile.exists()) {
            final fileSize = await altFile.length();
            debugPrint('File berhasil disalin dengan metode alternatif (ukuran: $fileSize bytes)');
            return altFile;
          }
        } catch (e) {
          debugPrint('Error saat mencoba metode alternatif: $e');
        }
        
        return originalFile; // Kembalikan file asli jika gagal menyalin
      }
    } catch (e) {
      debugPrint('Error saat menyalin gambar: $e');
      return originalFile; // Kembalikan file asli jika terjadi error
    }
  }
  
  // Mengidentifikasi flora atau fauna dari bytes gambar - universal untuk web dan mobile
  Future<IdentificationModel?> identifySpeciesFromBytes(Uint8List bytes) async {
    try {
      // Siapkan prompt untuk AI
      const promptText = '''
      Identifikasi spesies flora atau fauna dalam gambar ini. 
      Berikan hasil identifikasi dalam format JSON dengan struktur berikut:
      {
        "type": "flora" atau "fauna",
        "commonName": "nama umum spesies",
        "scientificName": "nama ilmiah spesies",
        "confidenceLevel": tingkat keyakinan (0-100),
        "description": "deskripsi tentang spesies",
        "habitat": "habitat spesies",
        "taxonomy": {
          "kingdom": "",
          "phylum": "",
          "class": "",
          "order": "",
          "family": "",
          "genus": "",
          "species": ""
        },
        "conservationStatus": "status konservasi"
      }
      ''';
      
      // Buat prompt dan image part
      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', bytes);
      
      // Buat permintaan ke Gemini dengan gambar dan prompt menggunakan Content.multi
      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      
      // Dapatkan teks respons
      final responseText = response.text;
      
      if (responseText == null) {
        throw Exception('Response kosong dari Gemini');
      }
      
      // Ekstrak JSON dari respons
      final jsonString = _extractJsonFromText(responseText);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Simpan gambar secara lokal
      final String imagePath = await _saveImageLocally(bytes);
      debugPrint('Gambar disimpan dengan path: $imagePath');
      
      // Buat model identifikasi
      return IdentificationModel(
        id: _uuid.v4(),
        imageUrl: imagePath,
        type: data['type'] ?? 'unknown',
        commonName: data['commonName'] ?? 'Tidak diketahui',
        scientificName: data['scientificName'] ?? 'Tidak diketahui',
        confidenceLevel: (data['confidenceLevel'] as num?)?.toDouble() != null
            ? ((data['confidenceLevel'] as num).toDouble() / 100) // Konversi dari 0-100 ke 0.0-1.0
            : 0.0,
        description: data['description'] ?? 'Tidak ada deskripsi',
        habitat: data['habitat'] ?? 'Tidak ada data habitat',
        taxonomy: _parseTaxonomy(data['taxonomy']),
        conservationStatus: data['conservationStatus'] ?? 'Tidak diketahui',
      );
    } catch (e) {
      debugPrint('Error saat identifikasi dari bytes: $e');
      return _createDummyIdentification();
    }
  }
  
  // Menyimpan gambar secara lokal
  Future<String> _saveImageLocally(Uint8List bytes) async {
    final uniqueId = _uuid.v4();
    
    // Jika platform web, gunakan ID saja tanpa menyimpan gambar
    if (kIsWeb) {
      debugPrint('Platform web terdeteksi, menggunakan placeholder');
      
      // Di produksi, disini kita bisa menyimpan gambar di IndexedDB atau localStorage
      // Tetapi untuk demo, kita hanya gunakan placeholder
      return ''; // Return string kosong untuk menggunakan placeholder otomatis
    }
    
    try {
      // Untuk platform mobile, simpan gambar seperti biasa
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/biodiva_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final String fileName = 'image_$uniqueId.jpg';
      final String permPath = '${imagesDir.path}/$fileName';
      
      // Simpan gambar langsung ke storage permanen
      final File permFile = File(permPath);
      await permFile.writeAsBytes(bytes);
      debugPrint('Mencoba menulis gambar ke: $permPath');
      
      // Verifikasi file sudah disimpan
      if (await permFile.exists()) {
        final fileSize = await permFile.length();
        debugPrint('Gambar berhasil disimpan di: $permPath (ukuran: $fileSize bytes)');
        return permPath;
      } else {
        debugPrint('Gagal menyimpan gambar ke storage permanen, mencoba lokasi temporary');
        
        // Coba simpan di direktori temporary sebagai fallback
        final tempDir = await getTemporaryDirectory();
        final imageName = 'temp_image_$uniqueId.jpg';
        final imagePath = '${tempDir.path}/$imageName';
        
        final tempFile = File(imagePath);
        await tempFile.writeAsBytes(bytes);
        
        if (await tempFile.exists()) {
          final fileSize = await tempFile.length();
          debugPrint('Gambar berhasil disimpan di temp: $imagePath (ukuran: $fileSize bytes)');
          return imagePath;
        }
        
        debugPrint('Semua upaya penyimpanan gagal, menggunakan placeholder');
        return ''; // Return string kosong untuk menggunakan placeholder otomatis
      }
    } catch (e) {
      debugPrint('Error saat menyimpan gambar: $e');
      // Gunakan placeholder dinamis jika gagal menyimpan
      return '';
    }
  }
  
  // Metode publik untuk mengakses dummy data
  IdentificationModel createDummyIdentification() {
    return _createDummyIdentification();
  }
  
  // Metode publik untuk membuat quiz dummy
  QuizModel createDummyQuiz(IdentificationModel identification) {
    return _createDummyQuiz(identification);
  }
  
  // Membuat data dummy untuk demo di web
  IdentificationModel _createDummyIdentification() {
    final bool isFlora = _uuid.v4().substring(0, 1).codeUnitAt(0) % 2 == 0;
    
    final String type = isFlora ? 'flora' : 'fauna';
    final String commonName = isFlora ? 'Anggrek Bulan' : 'Komodo';
    final String scientificName = isFlora ? 'Phalaenopsis amabilis' : 'Varanus komodoensis';
    
    final Map<String, String> taxonomy = isFlora
        ? {
            'kingdom': 'Plantae',
            'phylum': 'Tracheophyta',
            'class': 'Liliopsida',
            'order': 'Asparagales',
            'family': 'Orchidaceae',
            'genus': 'Phalaenopsis',
            'species': 'P. amabilis',
          }
        : {
            'kingdom': 'Animalia',
            'phylum': 'Chordata',
            'class': 'Reptilia',
            'order': 'Squamata',
            'family': 'Varanidae',
            'genus': 'Varanus',
            'species': 'V. komodoensis',
          };
    
    final String description = isFlora
        ? 'Anggrek Bulan adalah jenis anggrek yang sangat populer di Indonesia. Bunga ini memiliki kelopak putih yang indah dan sering digunakan sebagai simbol keindahan.'
        : 'Komodo adalah kadal terbesar di dunia yang hanya ditemukan di beberapa pulau di Indonesia. Hewan ini dikenal karena ukurannya yang besar dan gigitannya yang beracun.';
    
    final String habitat = isFlora
        ? 'Tumbuh di hutan-hutan tropis Indonesia, terutama di Jawa, Sumatra, dan Kalimantan.'
        : 'Endemik di beberapa pulau di Indonesia, terutama Pulau Komodo, Rinca, Flores, dan Gili Motang.';
    
    final String conservationStatus = isFlora ? 'Least Concern' : 'Endangered';
    
    // Gunakan string kosong untuk placeholder dinamis
    final String imagePath = '';
    
    debugPrint('Dummy identification dibuat dengan path gambar kosong - menggunakan placeholder dinamis');
    
    return IdentificationModel(
      id: _uuid.v4(),
      imageUrl: imagePath,
      type: type,
      commonName: commonName,
      scientificName: scientificName,
      confidenceLevel: 0.85, // Sudah dalam format 0.0-1.0
      description: description,
      habitat: habitat,
      taxonomy: taxonomy,
      conservationStatus: conservationStatus,
    );
  }
  
  // Menghasilkan quiz berdasarkan ID identifikasi
  Future<QuizModel?> generateQuizById(String identificationId, IdentificationModel identification) async {
    try {
      // Gunakan identification yang diberikan
      return generateQuiz(identification);
    } catch (e) {
      debugPrint('Error saat membuat quiz berdasarkan ID: $e');
      return null;
    }
  }
  
  // Menghasilkan quiz berdasarkan hasil identifikasi
  Future<QuizModel?> generateQuiz(IdentificationModel identification) async {
    try {
      // Siapkan prompt untuk AI
      final prompt = '''
      Buat quiz tentang ${identification.commonName} (${identification.scientificName}).
      
      Info tentang spesies ini:
      - Tipe: ${identification.type}
      - Nama umum: ${identification.commonName}
      - Nama ilmiah: ${identification.scientificName}
      - Deskripsi: ${identification.description}
      - Habitat: ${identification.habitat}
      - Taksonomi: ${json.encode(identification.taxonomy)}
      - Status konservasi: ${identification.conservationStatus}
      
      Buat 5 pertanyaan pilihan ganda tentang spesies ini dalam format JSON berikut:
      {
        "questions": [
          {
            "question": "pertanyaan 1",
            "options": ["opsi a", "opsi b", "opsi c", "opsi d"],
            "correctOptionIndex": indeks jawaban benar (0-3),
            "explanation": "penjelasan jawaban"
          },
          ...
        ]
      }
      ''';
      
      // Buat permintaan ke Gemini
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);
      
      // Dapatkan teks respons
      final responseText = response.text;
      
      if (responseText == null) {
        throw Exception('Response kosong dari Gemini');
      }
      
      // Ekstrak JSON dari respons
      final jsonString = _extractJsonFromText(responseText);
      final Map<String, dynamic> data = json.decode(jsonString);
      
      // Parse pertanyaan quiz
      final List<dynamic> questionsJson = data['questions'] as List<dynamic>;
      final List<QuizQuestion> questions = questionsJson.map((q) {
        return QuizQuestion(
          id: _uuid.v4(),
          question: q['question'],
          options: List<String>.from(q['options']),
          correctOptionIndex: q['correctOptionIndex'],
          explanation: q['explanation'],
        );
      }).toList();
      
      // Buat model quiz
      return QuizModel(
        id: _uuid.v4(),
        title: 'Quiz - ${identification.commonName}',
        identificationId: identification.id,
        questions: questions,
        type: identification.type,
      );
    } catch (e) {
      debugPrint('Error saat membuat quiz: $e');
      return _createDummyQuiz(identification);
    }
  }

  // Membuat quiz dummy untuk demo di web
  QuizModel _createDummyQuiz(IdentificationModel identification) {
    final bool isFlora = identification.type == 'flora';
    
    final List<QuizQuestion> questions = isFlora
        ? [
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Apa nama ilmiah dari Anggrek Bulan?',
              options: [
                'Phalaenopsis amabilis',
                'Dendrobium phalaenopsis',
                'Vanda tricolor',
                'Cattleya labiata',
              ],
              correctOptionIndex: 0,
              explanation: 'Anggrek Bulan memiliki nama ilmiah Phalaenopsis amabilis.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Anggrek Bulan termasuk dalam keluarga apa?',
              options: [
                'Rosaceae',
                'Orchidaceae',
                'Fabaceae',
                'Poaceae',
              ],
              correctOptionIndex: 1,
              explanation: 'Anggrek Bulan termasuk dalam keluarga Orchidaceae.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Di mana habitat asli Anggrek Bulan?',
              options: [
                'Amerika Selatan',
                'Afrika',
                'Asia Tenggara',
                'Australia',
              ],
              correctOptionIndex: 2,
              explanation: 'Anggrek Bulan berasal dari Asia Tenggara, termasuk Indonesia.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Apa warna kelopak bunga Anggrek Bulan yang paling umum?',
              options: [
                'Merah',
                'Kuning',
                'Putih',
                'Ungu',
              ],
              correctOptionIndex: 2,
              explanation: 'Anggrek Bulan paling umum memiliki kelopak berwarna putih.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Anggrek Bulan adalah bunga nasional negara mana?',
              options: [
                'Malaysia',
                'Indonesia',
                'Thailand',
                'Filipina',
              ],
              correctOptionIndex: 3,
              explanation: 'Anggrek Bulan adalah bunga nasional Filipina.',
            ),
          ]
        : [
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Apa nama ilmiah dari Komodo?',
              options: [
                'Varanus salvator',
                'Varanus komodoensis',
                'Draco volans',
                'Varanus giganteus',
              ],
              correctOptionIndex: 1,
              explanation: 'Komodo memiliki nama ilmiah Varanus komodoensis.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Di mana habitat asli Komodo?',
              options: [
                'Sulawesi',
                'Jawa',
                'Kalimantan',
                'Pulau Komodo dan sekitarnya',
              ],
              correctOptionIndex: 3,
              explanation: 'Komodo hanya ditemukan di beberapa pulau di Indonesia Timur, terutama Pulau Komodo, Rinca, Flores, dan Gili Motang.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Apa status konservasi Komodo saat ini?',
              options: [
                'Least Concern',
                'Vulnerable',
                'Endangered',
                'Critically Endangered',
              ],
              correctOptionIndex: 2,
              explanation: 'Komodo saat ini berstatus Endangered (Terancam Punah) menurut IUCN Red List.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Berapa panjang maksimal Komodo dewasa?',
              options: [
                '1-2 meter',
                '2-3 meter',
                '3-4 meter',
                'Lebih dari 4 meter',
              ],
              correctOptionIndex: 2,
              explanation: 'Komodo dewasa dapat mencapai panjang 3-4 meter.',
            ),
            QuizQuestion(
              id: _uuid.v4(),
              question: 'Apa yang membuat gigitan Komodo berbahaya?',
              options: [
                'Gigi yang sangat tajam',
                'Bakteri berbahaya di air liur',
                'Racun yang diproduksi kelenjar di rahang bawah',
                'Semua jawaban benar',
              ],
              correctOptionIndex: 3,
              explanation: 'Gigitan Komodo berbahaya karena kombinasi dari gigi tajam, bakteri di air liur, dan kelenjar racun yang telah ditemukan di rahang bawahnya.',
            ),
          ];
    
    return QuizModel(
      id: _uuid.v4(),
      title: 'Quiz - ${identification.commonName}',
      identificationId: identification.id,
      questions: questions,
      type: identification.type,
    );
  }
  
  // Ekstrak JSON dari respons teks
  String _extractJsonFromText(String text) {
    // Cari pattern JSON dalam respons
    final RegExp jsonPattern = RegExp(r'{.*}', dotAll: true);
    final match = jsonPattern.firstMatch(text);
    
    if (match != null) {
      return match.group(0)!;
    }
    
    throw Exception('Tidak dapat menemukan JSON dalam respons');
  }
  
  // Parse data taksonomi
  Map<String, String> _parseTaxonomy(dynamic taxonomyData) {
    if (taxonomyData == null || taxonomyData is! Map) {
      return {
        'kingdom': 'Tidak diketahui',
        'phylum': 'Tidak diketahui',
        'class': 'Tidak diketahui',
        'order': 'Tidak diketahui',
        'family': 'Tidak diketahui',
        'genus': 'Tidak diketahui',
        'species': 'Tidak diketahui',
      };
    }
    
    final Map<String, String> taxonomy = {};
    
    taxonomyData.forEach((key, value) {
      taxonomy[key.toString()] = value.toString();
    });
    
    return taxonomy;
  }
} 