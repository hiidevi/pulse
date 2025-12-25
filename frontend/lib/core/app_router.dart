import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/moments/screens/send_moment_screen.dart';
import '../features/moments/screens/memories_screen.dart';
import '../features/moments/screens/quick_reply_screen.dart';
import '../features/connections/screens/connection_search_screen.dart';
import '../features/profile/screens/profile_settings_screen.dart';
import '../features/moments/screens/moment_reveal_screen.dart';
import '../features/moments/screens/conversation_detail_screen.dart';
import '../features/profile/screens/profile_gallery_screen.dart';
import '../models/moment.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/quick-reply/:id/:name/:emoji',
        builder: (context, state) => QuickReplyScreen(
          momentId: int.parse(state.pathParameters['id']!),
          senderName: state.pathParameters['name']!,
          originalEmoji: state.pathParameters['emoji']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/memories',
        builder: (context, state) => const MemoriesScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const ConnectionSearchScreen(),
      ),
      GoRoute(
        path: '/send-moment/:id/:name',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final name = state.pathParameters['name']!;
          return SendMomentScreen(receiverId: id, receiverName: name);
        },
      ),
      GoRoute(
        path: '/reveal',
        builder: (context, state) {
          final moment = state.extra as Moment;
          return MomentRevealScreen(moment: moment);
        },
      ),
      GoRoute(
        path: '/conversation/:id/:name',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final name = state.pathParameters['name']!;
          return ConversationDetailScreen(otherUserId: id, otherUserName: name);
        },
      ),
      GoRoute(
        path: '/profile/gallery',
        builder: (context, state) => const ProfileGalleryScreen(),
      ),
    ],
  );
}
