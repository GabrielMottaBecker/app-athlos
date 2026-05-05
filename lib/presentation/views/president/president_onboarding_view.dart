import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';
import '../auth/login_view.dart';

// ─── President Onboarding View ────────────────────────────────────────────────
class PresidentOnboardingView extends StatelessWidget {
  const PresidentOnboardingView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PresidentOnboardingViewModel(),
      child: const _PresidentOnboardingContent(),
    );
  }
}

class _PresidentOnboardingContent extends StatefulWidget {
  const _PresidentOnboardingContent();
  @override
  State<_PresidentOnboardingContent> createState() => _PresidentOnboardingContentState();
}

class _PresidentOnboardingContentState extends State<_PresidentOnboardingContent> {
  final _atleticaController = TextEditingController();
  final _presidentController = TextEditingController();

  @override
  void dispose() {
    _atleticaController.dispose();
    _presidentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PresidentOnboardingViewModel>();
    final ext = context.athlos;
    final themeNotifier = context.read<ThemeNotifier>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.surfaceColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: ext.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(5)),
            child: const Icon(Icons.sports, color: Colors.white, size: 13)),
          const SizedBox(width: 7),
          Text('Create Atlética', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
      ),
      body: Column(children: [
        // Step indicator
        Container(
          color: ext.surfaceColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: List.generate(2, (i) {
            final active = i <= vm.step;
            final current = i == vm.step;
            return Expanded(child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 250),
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: active ? ext.primaryColor : ext.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: current ? ext.primaryColor : ext.borderColor)),
                child: Center(child: active && !current
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: current ? Colors.white : ext.textSecondary)))),
              if (i < 1) Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 250),
                height: 2, color: active ? ext.primaryColor : ext.borderColor)),
            ]));
          })),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (vm.step == 0) ..._buildStep0(context, vm, ext),
            if (vm.step == 1) ..._buildStep1(context, vm, ext, themeNotifier),
          ]),
        )),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ext.surfaceColor, border: Border(top: BorderSide(color: ext.borderColor))),
          child: Row(children: [
            if (vm.canGoBack) ...[
              Expanded(child: OutlinedButton(
                onPressed: () => context.read<PresidentOnboardingViewModel>().prevStep(),
                style: OutlinedButton.styleFrom(foregroundColor: ext.primaryColor, side: BorderSide(color: ext.borderColor), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text('Voltar'))),
              const SizedBox(width: 10),
            ],
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: () {
                context.read<PresidentOnboardingViewModel>()
                  ..setAtleticaName(_atleticaController.text)
                  ..setPresidentName(_presidentController.text);
                if (vm.canGoNext) {
                  context.read<PresidentOnboardingViewModel>().nextStep();
                } else {
                  final atletica = context.read<PresidentOnboardingViewModel>().buildAtleticaModel();
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => AtleticaCreatedView(
                      atleticaName: atletica.name,
                      presidentName: atletica.presidentName,
                      primaryColor: Color(atletica.primaryColorValue),
                    )));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ext.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(vm.step == 0 ? 'Próximo' : 'Finalizar Cadastro',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _buildStep0(BuildContext context, PresidentOnboardingViewModel vm, AthlosThemeExtension ext) => [
    Text('Crie sua\nAtlética', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.textPrimary, height: 1.2)),
    const SizedBox(height: 6),
    Text('Personalize sua organização com logo, cores e muito mais.', style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4)),
    const SizedBox(height: 20),
    Center(child: Container(width: 90, height: 90,
      decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: BorderRadius.circular(16), border: Border.all(color: ext.borderColor)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 28, color: ext.textSecondary),
        const SizedBox(height: 4),
        Text('Adicionar\nLogo', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: ext.textSecondary)),
      ]))),
    const SizedBox(height: 6),
    Center(child: Text('Selecionar Arquivo', style: TextStyle(fontSize: 11, color: ext.primaryColor, fontWeight: FontWeight.w500))),
    const SizedBox(height: 20),
    AthlosTextField(hint: 'Ex: Pantheon Nexgen 2021', label: 'NOME DA ATLÉTICA', controller: _atleticaController,
      onChanged: (v) => context.read<PresidentOnboardingViewModel>().setAtleticaName(v)),
    const SizedBox(height: 14),
    AthlosTextField(hint: 'Ex: Pandora Rouge', label: 'NOME DO PRESIDENTE', controller: _presidentController,
      onChanged: (v) => context.read<PresidentOnboardingViewModel>().setPresidentName(v)),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [ext.primaryColor, Color.lerp(ext.primaryColor, Colors.black, 0.3)!]), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pronto para liderar?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        const Text('Confira os dados de fundação da sua atlética antes de avançar.', style: TextStyle(fontSize: 10, color: Colors.white70, height: 1.4)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () {},
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54), padding: const EdgeInsets.symmetric(vertical: 10)),
            child: const Text('Visualizar', style: TextStyle(fontSize: 12)))),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => context.read<PresidentOnboardingViewModel>().nextStep(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
            child: Text('Personalizar\nCores', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ext.primaryColor)))),
        ]),
      ]),
    ),
  ];

  List<Widget> _buildStep1(BuildContext context, PresidentOnboardingViewModel vm, AthlosThemeExtension ext, ThemeNotifier themeNotifier) {
    final primaryColors = [const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFDB2777), const Color(0xFFDC2626), const Color(0xFFEA580C), const Color(0xFF16A34A), const Color(0xFF0D9488), const Color(0xFF4338CA)];
    final bgColors = [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9), const Color(0xFFFAF7F2), const Color(0xFFF0FDF4), const Color(0xFFEFF6FF), const Color(0xFFF5F3FF), const Color(0xFF0F172A), const Color(0xFF1E293B)];
    return [
      Text('Personalização', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.textPrimary, height: 1.2)),
      const SizedBox(height: 6),
      Text('Escolha as cores que representam sua atlética. Mudanças em tempo real.', style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4)),
      const SizedBox(height: 20),
      ColorPickerSection(
        title: 'Cor Primária', subtitle: 'Botões, ícones e destaques', icon: Icons.palette_outlined,
        colors: primaryColors, selected: vm.primaryColor,
        onSelect: (c) => context.read<PresidentOnboardingViewModel>().setPrimaryColor(c, themeNotifier)),
      const SizedBox(height: 14),
      ColorPickerSection(
        title: 'Cor de Fundo', subtitle: 'Background geral do app', icon: Icons.format_paint_outlined,
        colors: bgColors, selected: vm.backgroundColor,
        onSelect: (c) => context.read<PresidentOnboardingViewModel>().setBackgroundColor(c, themeNotifier)),
      const SizedBox(height: 20),
      Text('Preview ao Vivo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ext.textSecondary)),
      const SizedBox(height: 10),
      _MiniPreview(primary: vm.primaryColor, background: vm.backgroundColor),
    ];
  }
}

// ─── Mini Preview ─────────────────────────────────────────────────────────────
class _MiniPreview extends StatelessWidget {
  final Color primary, background;
  const _MiniPreview({required this.primary, required this.background});
  @override
  Widget build(BuildContext context) {
    final isDark = background.computeLuminance() < 0.2;
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(children: [
        AnimatedContainer(duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), border: Border(bottom: BorderSide(color: border))),
          child: Row(children: [
            Container(width: 18, height: 18, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(4)), child: const Icon(Icons.sports, color: Colors.white, size: 10)),
            const SizedBox(width: 5),
            Text('ATHLOS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: text, letterSpacing: 1.5)),
            const Spacer(),
            Icon(Icons.notifications_outlined, size: 14, color: text.withOpacity(0.5)),
          ])),
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
            child: Row(children: [
              CircleAvatar(radius: 14, backgroundColor: primary.withOpacity(0.2), child: Text('PA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: primary))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pedro Alves', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: text)),
                Text('Presidente', style: TextStyle(fontSize: 8, color: text.withOpacity(0.5))),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('Ativo', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: primary))),
            ])),
          const SizedBox(height: 8),
          AnimatedContainer(duration: const Duration(milliseconds: 400),
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(7)),
            child: const Center(child: Text('Confirmar Presença', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)))),
        ])),
      ]),
    );
  }
}

// ─── Atlética Created View ────────────────────────────────────────────────────
class AtleticaCreatedView extends StatefulWidget {
  final String atleticaName;
  final String presidentName;
  final Color primaryColor;
  const AtleticaCreatedView({super.key, required this.atleticaName, required this.presidentName, required this.primaryColor});
  @override
  State<AtleticaCreatedView> createState() => _AtleticaCreatedViewState();
}

class _AtleticaCreatedViewState extends State<AtleticaCreatedView> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(children: [
          const SizedBox(height: 16),
          ScaleTransition(scale: _scale, child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: widget.primaryColor, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: widget.primaryColor.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))]),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 52))),
          const SizedBox(height: 32),
          FadeTransition(opacity: _fade, child: SlideTransition(position: _slide, child: Column(children: [
            Text('Atlética criada\ncom sucesso! 🎉', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ext.textPrimary, height: 1.15)),
            const SizedBox(height: 12),
            Text(widget.atleticaName.isNotEmpty ? '"${widget.atleticaName}" está pronta para decolar.' : 'Sua atlética está pronta para decolar.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: ext.textSecondary, height: 1.5)),
            const SizedBox(height: 32),
            AthlosCard(child: Column(children: [
              _SummaryRow(icon: Icons.sports, label: 'Atlética', value: widget.atleticaName.isNotEmpty ? widget.atleticaName : 'Sem nome', ext: ext, color: widget.primaryColor),
              Divider(color: ext.borderColor, height: 20),
              _SummaryRow(icon: Icons.star_outline, label: 'Presidente', value: widget.presidentName.isNotEmpty ? widget.presidentName : 'Sem nome', ext: ext, color: widget.primaryColor),
              Divider(color: ext.borderColor, height: 20),
              _SummaryRow(icon: Icons.palette_outlined, label: 'Cor principal',
                value: '#${widget.primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
                ext: ext, color: widget.primaryColor, colorDot: widget.primaryColor),
            ])),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: widget.primaryColor.withOpacity(0.2))),
              child: Column(children: [
                _NextStep(number: '1', text: 'Faça login com seu perfil de Presidente', ext: ext, primary: widget.primaryColor),
                const SizedBox(height: 10),
                _NextStep(number: '2', text: 'Adicione membros pelo painel Admin', ext: ext, primary: widget.primaryColor),
                const SizedBox(height: 10),
                _NextStep(number: '3', text: 'Crie eventos e postagens para engajar', ext: ext, primary: widget.primaryColor),
              ])),
          ]))),
          const SizedBox(height: 32),
          FadeTransition(opacity: _fade, child: SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginView()), (r) => false),
            style: ElevatedButton.styleFrom(backgroundColor: widget.primaryColor, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Ir para o Login', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))))),
          const SizedBox(height: 12),
          FadeTransition(opacity: _fade, child: TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginView()), (r) => false),
            child: Text('Explorar como convidado', style: TextStyle(fontSize: 13, color: ext.textSecondary, fontWeight: FontWeight.w500)))),
        ]),
      )),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon; final String label, value; final AthlosThemeExtension ext; final Color color; final Color? colorDot;
  const _SummaryRow({required this.icon, required this.label, required this.value, required this.ext, required this.color, this.colorDot});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ext.textSecondary, letterSpacing: 0.5)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary)),
    ])),
    if (colorDot != null) Container(width: 20, height: 20, decoration: BoxDecoration(color: colorDot, shape: BoxShape.circle)),
  ]);
}

class _NextStep extends StatelessWidget {
  final String number, text; final AthlosThemeExtension ext; final Color primary;
  const _NextStep({required this.number, required this.text, required this.ext, required this.primary});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 22, height: 22, decoration: BoxDecoration(color: primary, shape: BoxShape.circle), child: Center(child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
    const SizedBox(width: 10),
    Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: ext.textPrimary, height: 1.3))),
  ]);
}
