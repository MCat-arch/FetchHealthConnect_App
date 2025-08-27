import 'package:aura/home_wrapper.dart';
import 'package:aura/pages/home.dart';
import 'package:aura/pages/manual_input_form.dart';
import 'package:aura/utils/init.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: GlobalKey<NavigatorState>(),
  redirect: (context, state) async {
    final isInit = await InitializationManager.isInitialized();
    if (state.uri.toString() == '/' && isInit) {
      return '/home';
    }
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeWrapper()),
    GoRoute(
      path: '/manual-label',
      builder: (context, state) => const ManualLabelPage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const Home()),
  ],
);
