import 'package:biodiva/providers/user_provider.dart';
import 'package:biodiva/screens/home_screen.dart';
import 'package:biodiva/screens/identification_detail_screen.dart';
import 'package:biodiva/screens/identifier_screen.dart';
import 'package:biodiva/screens/onboarding_screen.dart';
import 'package:biodiva/screens/quiz_detail_screen.dart';
import 'package:biodiva/screens/quiz_play_screen.dart';
import 'package:biodiva/screens/quiz_result_screen.dart';
import 'package:biodiva/screens/quiz_screen.dart';
import 'package:biodiva/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen - Layar pertama yang muncul
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding Screen - Layar setup nama pengguna
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Shell Route (Bottom Navigation Bar)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return HomeScreen(child: child);
        },
        routes: [
          // Home Tab
          GoRoute(
            path: '/beranda',
            name: 'beranda',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const HomeTab(),
            ),
          ),
          
          // Identifier Tab
          GoRoute(
            path: '/identifier',
            name: 'identifier',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const IdentifierScreen(),
            ),
            routes: [
              // Detail Identifikasi
              GoRoute(
                path: 'detail/:id',
                name: 'identifier_detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => IdentificationDetailScreen(
                  identificationId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          
          // Quiz Tab
          GoRoute(
            path: '/quiz',
            name: 'quiz',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const QuizScreen(),
            ),
            routes: [
              // Detail Quiz
              GoRoute(
                path: 'detail/:id',
                name: 'quiz_detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => QuizDetailScreen(
                  quizId: state.pathParameters['id']!,
                ),
              ),
              
              // Bermain Quiz
              GoRoute(
                path: 'play/:id',
                name: 'quiz_play',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => QuizPlayScreen(
                  quizId: state.pathParameters['id']!,
                ),
              ),
              
              // Hasil Quiz
              GoRoute(
                path: 'result/:id',
                name: 'quiz_result',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => QuizResultScreen(
                  attemptId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool isLoggedIn = Provider.of<UserProvider>(context, listen: false).isLoggedIn;
      
      // Jika belum login dan bukan ke splash atau onboarding, arahkan ke onboarding
      final bool goingToLogin = state.matchedLocation == '/splash' || state.matchedLocation == '/onboarding';
      
      if (!isLoggedIn && !goingToLogin) {
        return '/onboarding';
      }
      
      // Jika sudah login dan ke splash, langsung ke beranda
      if (isLoggedIn && state.matchedLocation == '/splash') {
        return '/beranda';
      }
      
      // Jika sudah login dan ke onboarding, langsung ke beranda
      if (isLoggedIn && state.matchedLocation == '/onboarding') {
        return '/beranda';
      }
      
      return null;
    },
  );
} 