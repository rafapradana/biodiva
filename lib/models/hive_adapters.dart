import 'package:biodiva/models/identification_model.dart';
import 'package:biodiva/models/quiz_model.dart';
import 'package:biodiva/models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Service untuk mengelola Hive database di aplikasi Biodiva
/// 
/// Class ini mengatur inisialisasi Hive, registrasi adapter,
/// dan pembukaan box untuk penyimpanan data.
class HiveService {
  // Nama box untuk penyimpanan data
  static const String userBox = 'userBox';
  static const String identificationsBox = 'identificationsBox';
  static const String quizzesBox = 'quizzesBox';

  /// Inisialisasi Hive database
  /// 
  /// Metode ini harus dipanggil di awal aplikasi sebelum menggunakan Hive
  static Future<void> init() async {
    try {
      // Platform web menggunakan pendekatan yang berbeda
      if (kIsWeb) {
        await Hive.initFlutter();
      } else {
        // Dapatkan direktori untuk menyimpan database
        final appDocumentDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDir.path);
      }

      // Registrasi adapter
      // File-file adapter sudah berhasil dibuat dengan build_runner
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(IdentificationModelAdapter());
      Hive.registerAdapter(QuizModelAdapter());
      Hive.registerAdapter(QuizQuestionAdapter());
      Hive.registerAdapter(QuizAttemptAdapter());

      // Buka box untuk penyimpanan data
      await Hive.openBox(userBox);
      await Hive.openBox(identificationsBox);
      await Hive.openBox(quizzesBox);
    } catch (e) {
      print('Error saat inisialisasi Hive: $e');
      // Gunakan inisialisasi dasar sebagai fallback
      await Hive.initFlutter();
      
      // Registrasi adapter
      Hive.registerAdapter(UserModelAdapter());
      Hive.registerAdapter(IdentificationModelAdapter());
      Hive.registerAdapter(QuizModelAdapter());
      Hive.registerAdapter(QuizQuestionAdapter());
      Hive.registerAdapter(QuizAttemptAdapter());
      
      // Buka box
      await Hive.openBox(userBox);
      await Hive.openBox(identificationsBox);
      await Hive.openBox(quizzesBox);
    }
  }
  
  /// Reset database - gunakan dengan hati-hati
  static Future<void> resetDatabase() async {
    await Hive.box(userBox).clear();
    await Hive.box(identificationsBox).clear();
    await Hive.box(quizzesBox).clear();
  }
}

// CATATAN PENGEMBANGAN:
// File-file adapter Hive (.g.dart) telah berhasil dibuat dengan perintah:
// flutter pub run build_runner build --delete-conflicting-outputs 