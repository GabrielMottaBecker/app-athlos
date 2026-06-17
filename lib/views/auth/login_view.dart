import 'package:athlos/core/theme/atletica_theme_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../user/user_main_view.dart';
import '../president/president_onboarding_view.dart';
import '../admin/admin_shell_view.dart';
import '../shared/widgets/widgets.dart';
import '../superadmin/super_admin_shell_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _LoginContent(),
    );
  }
}

class _LoginContent extends StatefulWidget {
  const _LoginContent();

  @override
  State<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<_LoginContent> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleNavigation(BuildContext context, String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SuperAdminShellView()));
        break;
      case 'ADMINISTRADOR':
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
    final vm  = context.watch<AuthViewModel>();
    final ext = context.athlos;

    if (vm.state == AuthState.success && vm.role != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await loadAtleticaTheme(context.read<ThemeNotifier>());
        if (context.mounted) _handleNavigation(context, vm.role!);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 28, right: 28, top: 32,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Logo ──────────────────────────────────────────────
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: ext.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('ATHLOS', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900,
                  color: ext.textPrimary, letterSpacing: 2.5,
                )),
              ]),
              const SizedBox(height: 40),

              // ── Título ────────────────────────────────────────────
              Text('Bem-vindo!', style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800,
                color: ext.textPrimary, height: 1.15,
              )),
              const SizedBox(height: 8),
              Text(
                'A plataforma definitiva para gestão e performance de atléticas universitárias.',
                style: TextStyle(fontSize: 13, color: ext.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Campo Email ───────────────────────────────────────
              AthlosTextField(
                hint: 'seu@email.com',
                label: 'E-MAIL',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // ── Campo Senha ───────────────────────────────────────
              AthlosTextField(
                hint: '••••••••',
                label: 'SENHA',
                controller: _passwordCtrl,
                obscureText: vm.obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    vm.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                    size: 18, color: ext.textSecondary,
                  ),
                  onPressed: () =>
                    context.read<AuthViewModel>().togglePasswordVisibility(),
                ),
              ),
              const SizedBox(height: 8),

              // ── Esqueceu a senha ──────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Text('Esqueceu a senha?', style: TextStyle(
                  fontSize: 12, color: ext.primaryColor,
                  fontWeight: FontWeight.w500,
                )),
              ),

              // ── Erro ──────────────────────────────────────────────
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(vm.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              // ── Botão Entrar ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.state == AuthState.loading
                    ? null
                    : () => context.read<AuthViewModel>().login(
                        _emailCtrl.text.trim(),
                        _passwordCtrl.text,
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ext.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: vm.state == AuthState.loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('ENTRAR', style: TextStyle(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
              ),
              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }
}