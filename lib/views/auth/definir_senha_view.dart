import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';
import '../user/user_main_view.dart';
import '../admin/admin_shell_view.dart';
import '../superadmin/super_admin_shell_view.dart';

class DefinirSenhaView extends StatefulWidget {
  const DefinirSenhaView({super.key});

  @override
  State<DefinirSenhaView> createState() => _DefinirSenhaViewState();
}

class _DefinirSenhaViewState extends State<DefinirSenhaView> {
  final _senhaCtrl = TextEditingController();
  final _confirmarSenhaCtrl = TextEditingController();

  @override
  void dispose() {
    _senhaCtrl.dispose();
    _confirmarSenhaCtrl.dispose();
    super.dispose();
  }

  void _handleNavigation(BuildContext context, String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const SuperAdminShellView()),
          (route) => false);
        break;
      case 'ADMINISTRADOR':
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const AdminShellView()),
          (route) => false);
        break;
      default:
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const UserMainView()),
          (route) => false);
    }
  }

  Future<void> _concluir(BuildContext context) async {
    final vm = context.read<AtivacaoContaViewModel>();
    final sucesso = await vm.definirSenha(_senhaCtrl.text, _confirmarSenhaCtrl.text);

    if (sucesso && context.mounted && vm.roleAposAtivar != null) {
      _handleNavigation(context, vm.roleAposAtivar!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<AtivacaoContaViewModel>();
    final ext = context.athlos;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: ext.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 28, right: 28, top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Ícone ─────────────────────────────────────────────
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: ext.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.lock_outline, color: ext.primaryColor, size: 26),
              ),
              const SizedBox(height: 24),

              // ── Título ────────────────────────────────────────────
              Text(
                vm.nomeMembro != null ? 'Olá, ${vm.nomeMembro}!' : 'Quase lá!',
                style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  color: ext.textPrimary, height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie uma senha para acessar o app da sua atlética.',
                style: TextStyle(fontSize: 13, color: ext.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Campo Senha ───────────────────────────────────────
              AthlosTextField(
                hint: 'Mínimo 8 caracteres',
                label: 'NOVA SENHA',
                controller: _senhaCtrl,
                obscureText: vm.obscurePassword,
                onChanged: (_) => vm.clearError(),
                suffixIcon: IconButton(
                  icon: Icon(
                    vm.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                    size: 18, color: ext.textSecondary,
                  ),
                  onPressed: () =>
                    context.read<AtivacaoContaViewModel>().togglePasswordVisibility(),
                ),
              ),
              const SizedBox(height: 16),

              // ── Campo Confirmar Senha ─────────────────────────────
              AthlosTextField(
                hint: 'Repita a senha',
                label: 'CONFIRMAR SENHA',
                controller: _confirmarSenhaCtrl,
                obscureText: vm.obscureConfirmarSenha,
                onChanged: (_) => vm.clearError(),
                suffixIcon: IconButton(
                  icon: Icon(
                    vm.obscureConfirmarSenha
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                    size: 18, color: ext.textSecondary,
                  ),
                  onPressed: () =>
                    context.read<AtivacaoContaViewModel>().toggleConfirmarSenhaVisibility(),
                ),
              ),

              // ── Erro ──────────────────────────────────────────────
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(vm.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              // ── Botão Concluir ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.state == AtivacaoState.loading
                    ? null
                    : () => _concluir(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ext.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: vm.state == AtivacaoState.loading
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('CONCLUIR ATIVAÇÃO', style: TextStyle(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}