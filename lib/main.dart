import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_notifier.dart';
import 'presentation/views/auth/splash_view.dart'; // ← adiciona isso

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const AthlosApp(),
    ),
  );
}

class AthlosApp extends StatelessWidget {
  const AthlosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'Athlos',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.buildTheme(),
      home: const SplashView(),
    );
  }
}