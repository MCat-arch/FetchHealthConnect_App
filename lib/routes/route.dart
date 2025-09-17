// import 'package:aura/home_wrapper.dart';
// import 'package:aura/pages/home.dart';
// import 'package:aura/pages/manual_input_form.dart';
// import 'package:aura/utils/init.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// final router = GoRouter(
//   initialLocation: '/',
//   navigatorKey: GlobalKey<NavigatorState>(),
//   redirect: (context, state) async {
//     final isInit = await InitializationManager.isInitialized();
//     final user = FirebaseAuth.instance.currentUser;
//     if (state.uri.toString() == '/' && isInit) {
//       return '/home';
//     }
//   },
//   routes: [
//     GoRoute(path: '/', builder: (context, state) => const HomeWrapper()),
//     GoRoute(
//       path: '/manual-label',
//       builder: (context, state) => const ManualLabelPage(),
//     ),
//     GoRoute(path: '/home', builder: (context, state) => const Home()),

//   ],
// );


import 'dart:async';
import 'package:aura/home_wrapper.dart';
import 'package:aura/pages/home.dart';
import 'package:aura/pages/login.dart';
import 'package:aura/pages/manual_input_form.dart';
import 'package:aura/pages/sign_up.dart';
import 'package:aura/utils/init.dart';
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
  // agar redirect dieksekusi ulang saat authStateChanges terjadi
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) async {
    // Note: redirect can be async
    final user = FirebaseAuth.instance.currentUser;
    final isInit = await InitializationManager.isInitialized();

    debugPrint(
      '[Router] redirect check -> path=${state.uri}, user=${user != null}, isInit=$isInit',
    );

    // Jika belum login -> arahkan ke /login (kecuali sedang di /login atau /signup)
    if (user == null &&
        state.matchedLocation != '/login' &&
        state.matchedLocation != '/signup') {
      return '/login';
    }

    // Jika sudah login dan app inisialisasi sudah selesai dan sedang di root '/', pindah ke /home
    if (user != null && state.matchedLocation == '/' && isInit) {
      return '/home';
    }

    // default: tidak redirect
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeWrapper()),
    GoRoute(path: '/home', builder: (context, state) => const Home()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/manual-label',
      builder: (context, state) => const ManualLabelPage(),
    ),
  ],
);
