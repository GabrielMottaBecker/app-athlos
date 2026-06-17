import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';
import '../auth/login_view.dart';
import '../../data/datasources/token_local_datasource.dart';
import '../../core/theme/theme_notifier.dart';
import '../../data/models/models.dart';

class SuperAdminShellView extends StatelessWidget {
  const SuperAdminShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperAdminAtleticasView();
  }
}

// ─── Super Admin AppBar ───────────────────────────────────────────────────────
class _SuperAdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  const _SuperAdminAppBar({required this.subtitle});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return AppBar(
      backgroundColor: ext.surfaceColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF7C3AED).withOpacity(0.15),
          child: const Text('SA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
        ),
      ),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Athlos Super Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        Text(subtitle, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
      ]),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: ext.textSecondary, size: 20),
          tooltip: 'Sair',
          onPressed: () async {
            await TokenLocalDatasource().clearTokens();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginView()),
              (r) => false,
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: ext.borderColor),
      ),
    );
  }
}

// ─── Atléticas View ───────────────────────────────────────────────────────────
class SuperAdminAtleticasView extends StatefulWidget {
  const SuperAdminAtleticasView({super.key});
  @override
  State<SuperAdminAtleticasView> createState() => _SuperAdminAtleticasViewState();
}

class _SuperAdminAtleticasViewState extends State<SuperAdminAtleticasView> {
  late final SuperAdminViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = SuperAdminViewModel();
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
      child: const _AtleticasContent(),
    );
  }
}

class _AtleticasContent extends StatelessWidget {
  const _AtleticasContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SuperAdminViewModel>();
    final ext = context.athlos;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: const _SuperAdminAppBar(subtitle: 'GESTÃO DE ATLÉTICAS'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7C3AED),
        mini: true,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterAtleticaView()),
          );
          if (context.mounted) context.read<SuperAdminViewModel>().load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.atleticas.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.sports_outlined, size: 48, color: ext.textSecondary.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('Nenhuma atlética cadastrada.', style: TextStyle(fontSize: 14, color: ext.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Toque em + para criar a primeira.', style: TextStyle(fontSize: 12, color: ext.textSecondary.withOpacity(0.6))),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.atleticas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final a = vm.atleticas[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SuperAdminAtleticaDetailView(atletica: a))),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ext.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ext.borderColor),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Color(a.primaryColorValue).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.sports, color: Color(a.primaryColorValue), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Presidente: ${a.presidentName}', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
                          ])),
                          Container(width: 20, height: 20,
                            decoration: BoxDecoration(color: Color(a.primaryColorValue), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 16, color: ext.textSecondary),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─── Cadastrar Atlética ───────────────────────────────────────────────────────
class RegisterAtleticaView extends StatefulWidget {
  const RegisterAtleticaView({super.key});
  @override
  State<RegisterAtleticaView> createState() => _RegisterAtleticaViewState();
}

class _RegisterAtleticaViewState extends State<RegisterAtleticaView> {
  final _nomeCtrl       = TextEditingController();
  final _presidenteCtrl = TextEditingController();
  final _emailAdminCtrl = TextEditingController();
  final _senhaAdminCtrl = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _presidenteCtrl.dispose();
    _emailAdminCtrl.dispose();
    _senhaAdminCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return ChangeNotifierProvider(
      create: (_) => RegisterAtleticaViewModel(),
      child: Builder(builder: (context) {
        final vm = context.watch<RegisterAtleticaViewModel>();
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: ext.backgroundColor,
          appBar: AppBar(
            backgroundColor: ext.surfaceColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: ext.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Nova Atlética', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
            bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
          ),
          body: ListView(padding: const EdgeInsets.all(20), children: [
            Text('Dados da Atlética', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            AthlosTextField(hint: 'Ex: Pantheon Nexgen', label: 'NOME DA ATLÉTICA', controller: _nomeCtrl),
            const SizedBox(height: 12),
            AthlosTextField(hint: 'Ex: Gabriel Breier', label: 'NOME DO PRESIDENTE', controller: _presidenteCtrl),
            const SizedBox(height: 24),
            Text('Acesso do Administrador', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('Será criado um usuário ADMINISTRADOR para esta atlética.', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
            const SizedBox(height: 12),
            AthlosTextField(hint: 'admin@atletica.com', label: 'E-MAIL DO ADMIN', controller: _emailAdminCtrl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AthlosTextField(hint: '••••••••', label: 'SENHA DO ADMIN', controller: _senhaAdminCtrl, obscureText: true),
            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Text(vm.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: vm.isLoading ? null : () async {
                final success = await context.read<RegisterAtleticaViewModel>().save(
                  nome:         _nomeCtrl.text.trim(),
                  presidente:   _presidenteCtrl.text.trim(),
                  emailAdmin:   _emailAdminCtrl.text.trim(),
                  senhaAdmin:   _senhaAdminCtrl.text.trim(),
                );
                if (success && context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: vm.isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('CRIAR ATLÉTICA', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            )),
          ]),
        );
      }),
    );
  }
}

// ─── Detalhe da Atlética (Super Admin) ───────────────────────────────────────
class SuperAdminAtleticaDetailView extends StatelessWidget {
  final AtleticaModel atletica;
  const SuperAdminAtleticaDetailView({super.key, required this.atletica});

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    final primary = Color(atletica.primaryColorValue);

    return Scaffold(
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.surfaceColor, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: ext.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(atletica.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Header
        Center(child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: primary.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(Icons.sports, color: primary, size: 40),
        )),
        const SizedBox(height: 16),
        Center(child: Text(atletica.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.textPrimary))),
        const SizedBox(height: 4),
        Center(child: Text('Presidente: ${atletica.presidentName}', style: TextStyle(fontSize: 13, color: ext.textSecondary))),
        const SizedBox(height: 24),

        // Dados
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ext.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.borderColor)),
          child: Column(children: [
            _DetailRow(label: 'ID', value: atletica.id, ext: ext),
            Divider(color: ext.borderColor, height: 20),
            _DetailRow(label: 'Nome', value: atletica.name, ext: ext),
            Divider(color: ext.borderColor, height: 20),
            _DetailRow(label: 'Presidente', value: atletica.presidentName, ext: ext),
            Divider(color: ext.borderColor, height: 20),
            Row(children: [
              Expanded(child: Text('Cor Primária', style: TextStyle(fontSize: 12, color: ext.textSecondary))),
              Container(width: 24, height: 24, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('#${primary.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.textPrimary)),
            ]),
          ]),
        ),
        const SizedBox(height: 24),

        // Ação inativar
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () => _confirmInativar(context),
          icon: const Icon(Icons.block, size: 16, color: Color(0xFFEF4444)),
          label: const Text('Inativar Atlética', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        )),
      ]),
    );
  }

  Future<void> _confirmInativar(BuildContext context) async {
    final ext = context.athlos;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ext.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Inativar atlética', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        content: Text('Tem certeza que deseja inativar "${atletica.name}"? Os usuários não conseguirão acessar.', style: TextStyle(fontSize: 13, color: ext.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: ext.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Inativar', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // TODO: implementar endpoint de inativar atlética no backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidade em desenvolvimento.')),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final AthlosThemeExtension ext;
  const _DetailRow({required this.label, required this.value, required this.ext});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: ext.textSecondary))),
    Flexible(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.textPrimary), textAlign: TextAlign.right)),
  ]);
}