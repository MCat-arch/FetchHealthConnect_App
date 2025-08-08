import 'package:app_aura/pages/home.dart';
import 'package:app_aura/pages/manual_label.dart';
import 'package:app_aura/providers/health_provider.dart';
import 'package:app_aura/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_aura/routes/route.dart' as route;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HealthProvider(),
        ),
      ],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(primarySwatch: Colors.teal),
      routerConfig: route.router,
      debugShowCheckedModeBanner: false,
    );
  }
}


//connect to ui 
//threshold using armd
