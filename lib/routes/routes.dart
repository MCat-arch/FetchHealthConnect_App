import 'dart:async';
import 'package:aura_bluetooth/utils/init.dart';
import 'package:aura_bluetooth/views/breathing_page.dart';
import 'package:aura_bluetooth/views/home_page.dart';
import 'package:aura_bluetooth/views/login.dart';
import 'package:aura_bluetooth/views/register.dart';
import 'package:aura_bluetooth/views/setting.dart';
import 'package:aura_bluetooth/widgets/stats.dart';
import 'package:aura_bluetooth/widgets/home_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Utility class to notify GoRouter when stream emits (FirebaseAuth stream)
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen(
      (_) {
        // Notify router to reevaluate redirect
        notifyListeners();
      },
      onError: (err) {
        // opsional: debug
        debugPrint('[GoRouterRefreshStream] error: $err');
      },
    );
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: GlobalKey<NavigatorState>(),
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),

  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;

    final isLogin = state.matchedLocation == "/login";
    final isSignup = state.matchedLocation == "/signup";
    final isRoot = state.matchedLocation == "/";

    if (user == null) {
      if (!isLogin && !isSignup) return "/login";
      return null;
    }

    if (user != null && (isLogin || isSignup || isRoot)) {
      return "/";
    }

    return null;
  },

  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeWrapper()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpPage()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/setting', builder: (_, __) => const SettingPage()),
    // GoRoute(path: '/stats', builder: (_, __) => const StatisticsWidget()),
    GoRoute(path: '/breathing', builder: (_, __) => const BreathingGuidePage()),
  ],
);
