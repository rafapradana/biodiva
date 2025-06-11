import 'package:biodiva/config/router.dart';
import 'package:biodiva/constants/app_strings.dart';
import 'package:biodiva/constants/app_theme.dart';
import 'package:biodiva/models/hive_adapters.dart';
import 'package:biodiva/providers/identification_provider.dart';
import 'package:biodiva/providers/quiz_provider.dart';
import 'package:biodiva/providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load .env file
    await dotenv.load().catchError((e) {
      debugPrint('Error saat memuat .env: $e');
      // Jangan throw exception agar aplikasi tetap berjalan
    });
    
    // Inisialisasi Hive database
    await HiveService.init();
  } catch (e) {
    debugPrint('Error saat inisialisasi aplikasi: $e');
    // Jangan throw exception agar aplikasi tetap berjalan
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Tampilkan peringatan jika berjalan di web
    if (kIsWeb) {
      debugPrint('''
      ================================
      APLIKASI BERJALAN DI PLATFORM WEB
      Beberapa fitur mungkin terbatas karena keterbatasan platform web.
      Untuk pengalaman terbaik, gunakan aplikasi di perangkat mobile.
      ================================
      ''');
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => IdentificationProvider()..init()),
        ChangeNotifierProvider(create: (_) => QuizProvider()..init()),
      ],
      child: Builder(
        builder: (context) {
          // Inisialisasi router dengan provider
          return MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            routerConfig: AppRouter.router,
          );
        }
      ),
    );
  }
}
