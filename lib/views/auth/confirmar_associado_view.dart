import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';
import 'definir_senha_view.dart';

class ConfirmarAssociadoView extends StatelessWidget {
  const ConfirmarAssociadoView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AtivacaoContaViewModel(),
      child: const _ConfirmarAssociadoContent(),
    );
  }
}

class _ConfirmarAssociadoContent extends StatefulWidget {
  const _ConfirmarAssociadoContent();

  @override
  State<_ConfirmarAssociadoContent> createState() => _ConfirmarAssociadoContentState();
}

class _ConfirmarAssociadoContentState extends State<_ConfirmarAssociadoContent> {
  final _emailCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _continuar(BuildContext context) async {
    final vm = context.read<AtivacaoContaViewModel>();
    final sucesso = await vm.verificarAssociado(_emailCtrl.text, _telefoneCtrl.text);

    if (sucesso && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: vm,
            child: const DefinirSenhaView(),
          ),
        ),
      );
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
                child: Icon(Icons.badge_outlined, color: ext.primaryColor, size: 26),
              ),
              const SizedBox(height: 24),

              // ── Título ────────────────────────────────────────────
              Text('Ativar minha conta', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: ext.textPrimary, height: 1.2,
              )),
              const SizedBox(height: 8),
              Text(
                'Confirme o e-mail e o telefone que sua atlética cadastrou para você.',
                style: TextStyle(fontSize: 13, color: ext.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Campo Email ───────────────────────────────────────
              AthlosTextField(
                hint: 'seu@email.com',
                label: 'E-MAIL',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => vm.clearError(),
              ),
              const SizedBox(height: 16),

              // ── Campo Telefone ────────────────────────────────────
              AthlosTextField(
                hint: '(44) 99999-9999',
                label: 'TELEFONE',
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (_) => vm.clearError(),
              ),

              // ── Erro ──────────────────────────────────────────────
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(vm.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              // ── Botão Continuar ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.state == AtivacaoState.loading
                    ? null
                    : () => _continuar(context),
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
                    : const Text('CONTINUAR', style: TextStyle(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Esses dados foram informados pelo presidente da sua atlética no momento do seu cadastro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: ext.textSecondary, height: 1.5),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}