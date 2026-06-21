import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';

class AtleticaSettingsView extends StatefulWidget {
  const AtleticaSettingsView({super.key});
  @override
  State<AtleticaSettingsView> createState() => _AtleticaSettingsViewState();
}

class _AtleticaSettingsViewState extends State<AtleticaSettingsView> {
  late final AtleticaSettingsViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AtleticaSettingsViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.load());
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: const _AtleticaSettingsContent(),
    );
  }
}

class _AtleticaSettingsContent extends StatefulWidget {
  const _AtleticaSettingsContent();
  @override
  State<_AtleticaSettingsContent> createState() => _AtleticaSettingsContentState();
}

class _AtleticaSettingsContentState extends State<_AtleticaSettingsContent> {
  late TextEditingController _nomeCtrl;
  late TextEditingController _presidenteCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _presidenteCtrl.dispose();
    super.dispose();
  }

  void _initControllers(AtleticaSettingsViewModel vm) {
    if (_initialized) return;
    _nomeCtrl       = TextEditingController(text: vm.nome);
    _presidenteCtrl = TextEditingController(text: vm.nomePresidente);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<AtleticaSettingsViewModel>();
    final ext = context.athlos;
    final themeNotifier = context.read<ThemeNotifier>();

    if (vm.isLoading) {
      return Scaffold(
        backgroundColor: ext.backgroundColor,
        appBar: AppBar(
          backgroundColor: ext.surfaceColor, elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: ext.textPrimary), onPressed: () => Navigator.pop(context)),
          title: Text('Configurações da Atlética', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _initControllers(vm);

    final primaryColors = [
      const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFDB2777),
      const Color(0xFFDC2626), const Color(0xFFEA580C), const Color(0xFF16A34A),
      const Color(0xFF0D9488), const Color(0xFF4338CA),
    ];
    final bgColors = [
      const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFFAF7F2),
      const Color(0xFFF0FDF4), const Color(0xFFEFF6FF), const Color(0xFFF5F3FF),
      const Color(0xFF0F172A), const Color(0xFF1E293B),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.surfaceColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: ext.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('Configurações da Atlética', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Dados da Atlética', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        AthlosTextField(hint: 'Nome da atlética', label: 'NOME DA ATLÉTICA', controller: _nomeCtrl),
        const SizedBox(height: 12),
        AthlosTextField(hint: 'Nome do presidente', label: 'NOME DO PRESIDENTE', controller: _presidenteCtrl),
        const SizedBox(height: 24),
        Text('Cores', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 12),
        ColorPickerSection(
          title: 'Cor Primária',
          subtitle: 'Botões, ícones e destaques',
          icon: Icons.palette_outlined,
          colors: primaryColors,
          selected: vm.corPrimaria,
          onSelect: (c) {
            context.read<AtleticaSettingsViewModel>().setCorPrimaria(c);
            themeNotifier.setPrimaryColor(c);
          },
        ),
        const SizedBox(height: 12),
        ColorPickerSection(
          title: 'Cor de Fundo',
          subtitle: 'Background geral do app',
          icon: Icons.format_paint_outlined,
          colors: bgColors,
          selected: vm.corFundo,
          onSelect: (c) {
            context.read<AtleticaSettingsViewModel>().setCorFundo(c);
            themeNotifier.setBackgroundColor(c);
          },
        ),
        if (vm.error != null) ...[
          const SizedBox(height: 12),
          Text(vm.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: vm.isSaving ? null : () async {
            final success = await context.read<AtleticaSettingsViewModel>().save(
              nome:         _nomeCtrl.text.trim(),
              nomePresidente: _presidenteCtrl.text.trim(),
            );
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Atlética atualizada com sucesso!')),
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ext.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: vm.isSaving
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('SALVAR ALTERAÇÕES', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 40),
      ]),
    );
  }
}