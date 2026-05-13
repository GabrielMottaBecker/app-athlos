import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_notifier.dart';
import 'views/auth/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  await Firebase.initializeApp();

  // 2. Inicializar serviço de notificações push
  //    O handler de background já é registrado internamente pelo NotificationService.
  await NotificationService.instance.init(
    onNotificationTap: (message) {
      // TODO: navegar para a tela de agenda quando o usuário tocar na notificação.
      // Exemplo (implemente após ter um NavigatorKey global):
      // navigatorKey.currentState?.push(
      //   MaterialPageRoute(builder: (_) => const AgendaView()),
      // );
      debugPrint('[App] Usuário tocou na notificação: ${message.data}');
    },
  );

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
      home: const LoginView(),
    );
  }
}