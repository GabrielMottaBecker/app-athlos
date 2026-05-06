import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_notifier.dart';
import 'views/auth/login_view.dart';

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
    // ThemeNotifier é escutado aqui — qualquer mudança de cor reconstrói o MaterialApp
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      title: 'Athlos',
      debugShowCheckedModeBanner: false,
      theme: themeNotifier.buildTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: const LoginView(),
    );
  }
}
