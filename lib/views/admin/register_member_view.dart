import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';

class RegisterMemberView extends StatelessWidget {
  const RegisterMemberView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterMemberViewModel(),
      child: const _RegisterMemberContent(),
    );
  }
}

class _RegisterMemberContent extends StatefulWidget {
  const _RegisterMemberContent();
  @override
  State<_RegisterMemberContent> createState() => _RegisterMemberContentState();
}

class _RegisterMemberContentState extends State<_RegisterMemberContent> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _raController = TextEditingController();
  final _cursoController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _raController.dispose();
    _cursoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterMemberViewModel>();
    final ext = context.athlos;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AthlosAppBar(title: 'Cadastrar Membro'),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cadastrar\nMembro', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.textPrimary, height: 1.2)),
            const SizedBox(height: 6),
            Text('Adicione novos talentos e defina seus papéis na organização.',
              style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4)),
            const SizedBox(height: 20),

            // Informações Gerais
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.person_outline, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Informações Gerais', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              AthlosTextField(hint: 'Ex: Lucas Silva de Oliveira', label: 'NOME COMPLETO', controller: _nameController),
              const SizedBox(height: 12),
              AthlosTextField(hint: 'lucas@email.com', label: 'EMAIL', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AthlosTextField(hint: '000000', label: 'RA', controller: _raController, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: AthlosTextField(hint: 'Ex: Engenharia', label: 'CURSO', controller: _cursoController)),
              ]),
            ])),
            const SizedBox(height: 14),

            // Definição de Papel
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.badge_outlined, size: 16, color: ext.primaryColor),
                const SizedBox(width: 6),
                Text('Definição de Papel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: RegisterMemberViewModel.roles.map((r) {
                  final sel = r == vm.selectedRole;
                  return GestureDetector(
                    onTap: () => context.read<RegisterMemberViewModel>().setRole(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80, height: 72,
                      decoration: BoxDecoration(
                        color: sel ? ext.primaryColor : ext.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sel ? ext.primaryColor : ext.borderColor)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.person, size: 24, color: sel ? Colors.white : ext.textSecondary),
                        const SizedBox(height: 4),
                        Text(r, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sel ? Colors.white : ext.textSecondary)),
                      ]),
                    ),
                  );
                }).toList()),
            ])),
            const SizedBox(height: 14),

            // Dica
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white70, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Dica do Sistema', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  const Text('Este membro terá acesso à atlética conforme as permissões do papel selecionado.',
                    style: TextStyle(fontSize: 11, color: Colors.white70, height: 1.4)),
                ])),
              ]),
            ),
            const SizedBox(height: 14),

            // Estatísticas
            AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Associação Atual', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
              const SizedBox(height: 12),
              _StatRow('Total de Membros', '104', ext),
              _StatRow('Vagos', '36', ext),
              _StatRow('Novos este mês', '+12', ext, color: const Color(0xFF10B981)),
            ])),
          ]),
        )),

        // Botões
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ext.surfaceColor, border: Border(top: BorderSide(color: ext.borderColor))),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ext.primaryColor, side: BorderSide(color: ext.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 13)),
              child: const Text('Cancelar'))),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: ElevatedButton.icon(
              onPressed: vm.isLoading ? null : () async {
                final ok = await context.read<RegisterMemberViewModel>().register(
                  name: _nameController.text,
                  email: _emailController.text,
                  ra: _raController.text,
                  curso: _cursoController.text,
                );
                if (ok && context.mounted) Navigator.pop(context);
              },
              icon: vm.isLoading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add, size: 16, color: Colors.white),
              label: Text(vm.isLoading ? 'Registrando...' : 'Registrar →',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
          ]),
        ),
      ]),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final AthlosThemeExtension ext;
  final Color? color;
  const _StatRow(this.label, this.value, this.ext, {this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? ext.textPrimary)),
    ]));
}
