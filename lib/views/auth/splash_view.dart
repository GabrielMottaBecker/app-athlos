import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/token_local_datasource.dart';
import '../../core/theme/theme_notifier.dart';
import '../../core/theme/atletica_theme_loader.dart';
import 'login_view.dart';
import '../user/user_main_view.dart';
import '../president/president_onboarding_view.dart';
import '../admin/admin_shell_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final ds    = TokenLocalDatasource();
    final token = await ds.getAccessToken();
    final role  = await ds.getRole();

    if (!mounted) return;

    if (token == null || role == null) {
      // Sem token → vai para login
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginView()));
      return;
    }

    await loadAtleticaTheme(context.read<ThemeNotifier>());
    if (!mounted) return;

    // Com token → navega conforme o role salvo
    switch (role) {
      case 'president':
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PresidentOnboardingView()));
        break;
      case 'admin':
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AdminShellView()));
        break;
      default:
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const UserMainView()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}