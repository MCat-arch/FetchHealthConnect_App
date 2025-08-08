import 'package:app_aura/home_wrapper.dart';
import 'package:app_aura/pages/home.dart';
import 'package:app_aura/pages/manual_label.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: GlobalKey<NavigatorState>(),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeWrapper()),
    GoRoute(
      path: '/manual-label',
      builder: (context, state) => const ManualLabelPage(),
    ),
  ],
);