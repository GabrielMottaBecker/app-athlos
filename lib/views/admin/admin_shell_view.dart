import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_notifier.dart';
import '../../data/models/models.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';
import 'register_member_view.dart';

class AdminShellView extends StatefulWidget {
  const AdminShellView({super.key});
  @override
  State<AdminShellView> createState() => _AdminShellViewState();
}

class _AdminShellViewState extends State<AdminShellView> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    final tabs = const [AdminLojaView(), AdminAgendaView(), AdminFeedView(), AdminMembrosView()];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      body: tabs[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: ext.surfaceColor, border: Border(top: BorderSide(color: ext.borderColor))),
        child: BottomNavigationBar(
          currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
          backgroundColor: ext.surfaceColor,
          selectedItemColor: ext.primaryColor,
          unselectedItemColor: ext.textSecondary.withOpacity(0.5),
          type: BottomNavigationBarType.fixed, elevation: 0,
          selectedFontSize: 10, unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Loja'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Agenda'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Membros'),
          ],
        ),
      ),
    );
  }
}

// ─── Admin AppBar ─────────────────────────────────────────────────────────────
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final List<Widget>? actions;
  const AdminAppBar({super.key, required this.subtitle, this.actions});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    return AppBar(
      backgroundColor: ext.surfaceColor, elevation: 0, automaticallyImplyLeading: false,
      leading: Padding(padding: const EdgeInsets.all(10),
        child: CircleAvatar(backgroundColor: ext.primaryColor.withOpacity(0.15),
          child: Text('AA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ext.primaryColor)))),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Athlos Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        Text(subtitle, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
      ]),
      actions: actions ?? [
        IconButton(icon: Icon(Icons.add_circle_outline, color: ext.primaryColor, size: 22), onPressed: () {}),
        IconButton(icon: Icon(Icons.more_vert, color: ext.textSecondary, size: 22), onPressed: () {}),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
    );
  }
}

// ─── Admin Loja View ──────────────────────────────────────────────────────────
class AdminLojaView extends StatelessWidget {
  const AdminLojaView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminLojaViewModel(),
      child: const _AdminLojaContent(),
    );
  }
}

class _AdminLojaContent extends StatelessWidget {
  const _AdminLojaContent();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminLojaViewModel>();
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: AdminAppBar(subtitle: 'GESTÃO DA LOJA'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ext.primaryColor, mini: true, onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AthlosCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lojinha da Atlética', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          const SizedBox(height: 4),
          Text('R\$ ${vm.totalRevenue.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ext.primaryColor)),
          Text('${vm.totalSales} vendas', style: TextStyle(fontSize: 12, color: ext.textSecondary)),
          const SizedBox(height: 12),
          FilterChipRow(
            filters: AdminLojaViewModel.categories,
            activeFilter: vm.activeCategory,
            onSelect: (c) => context.read<AdminLojaViewModel>().setCategory(c),
          ),
        ])),
        const SizedBox(height: 14),
        ...vm.products.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: ext.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.borderColor)),
          child: Column(children: [
            Container(height: 140, decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: Center(child: Icon(Icons.checkroom_outlined, size: 44, color: ext.textSecondary.withOpacity(0.25)))),
            Padding(padding: const EdgeInsets.all(12), child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.textPrimary)),
                Text('• adicionar tamanhos', style: TextStyle(fontSize: 10, color: ext.textSecondary)),
              ])),
              Text('R\$ ${p.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ext.primaryColor)),
              const SizedBox(width: 10),
              GestureDetector(child: Icon(Icons.edit_outlined, size: 16, color: ext.textSecondary)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.read<AdminLojaViewModel>().removeProduct(p.id),
                child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444))),
            ])),
          ]),
        )).toList(),
      ]),
    );
  }
}

// ─── Admin Agenda View ────────────────────────────────────────────────────────
class AdminAgendaView extends StatelessWidget {
  const AdminAgendaView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminAgendaViewModel(),
      child: const _AdminAgendaContent(),
    );
  }
}

class _AdminAgendaContent extends StatelessWidget {
  const _AdminAgendaContent();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminAgendaViewModel>();
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: AdminAppBar(subtitle: 'GESTÃO DA AGENDA'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ext.primaryColor, mini: true, onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Text('Agenda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          const Spacer(),
          _Chip('${vm.todayCount} HOJE', const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _Chip('${vm.weekCount} SEMANA', const Color(0xFFF59E0B)),
        ]),
        const SizedBox(height: 16),
        ...vm.items.map((item) {
          final typeColor = Color(item.typeColor);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: ext.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.borderColor)),
            child: Column(children: [
              if (item.hasImage) Container(height: 100, decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: Center(child: Icon(Icons.image_outlined, size: 32, color: ext.textSecondary.withOpacity(0.3)))),
              Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(item.type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: typeColor))),
                const Spacer(),
                Text(item.date, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
                const SizedBox(width: 8),
                GestureDetector(child: Icon(Icons.edit_outlined, size: 14, color: ext.textSecondary)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => context.read<AdminAgendaViewModel>().removeItem(item.id),
                  child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444))),
              ])),
              Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(item.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary, height: 1.3))),
            ]),
          );
        }).toList(),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)));
}

// ─── Admin Feed View ──────────────────────────────────────────────────────────
class AdminFeedView extends StatelessWidget {
  const AdminFeedView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminFeedViewModel(),
      child: const _AdminFeedContent(),
    );
  }
}

class _AdminFeedContent extends StatelessWidget {
  const _AdminFeedContent();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFeedViewModel>();
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: AdminAppBar(subtitle: 'GESTÃO DO FEED'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ext.primaryColor, mini: true, onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AthlosTextField(
          hint: 'Buscar postagens ou avisos...',
          onChanged: (v) => context.read<AdminFeedViewModel>().setSearchQuery(v),
        ),
        const SizedBox(height: 14),
        Text('Postagens Recentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        const SizedBox(height: 10),
        ...vm.posts.map((p) {
          final typeColor = Color(p.categoryColor);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ext.surfaceColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: ext.borderColor)),
            child: Row(children: [
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.article_outlined, size: 18, color: typeColor)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                  child: Text(p.category, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: typeColor))),
                const SizedBox(height: 4),
                Text(p.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ext.textPrimary, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(p.timeAgo, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
              ])),
              const SizedBox(width: 8),
              GestureDetector(child: Icon(Icons.edit_outlined, size: 14, color: ext.textSecondary)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.read<AdminFeedViewModel>().removePost(p.id),
                child: const Icon(Icons.delete_outline, size: 14, color: Color(0xFFEF4444))),
            ]),
          );
        }).toList(),
      ]),
    );
  }
}

// ─── Admin Membros View ───────────────────────────────────────────────────────
class AdminMembrosView extends StatelessWidget {
  const AdminMembrosView({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminMembersViewModel(),
      child: const _AdminMembrosContent(),
    );
  }
}

class _AdminMembrosContent extends StatefulWidget {
  const _AdminMembrosContent();
  @override
  State<_AdminMembrosContent> createState() => _AdminMembrosContentState();
}

class _AdminMembrosContentState extends State<_AdminMembrosContent> {
  Future<void> _openRegisterMember() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const RegisterMemberView()),
    );
    if (context.mounted) context.read<AdminMembersViewModel>().refresh();
  }

  Future<void> _openEditMember(MemberModel member) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => RegisterMemberView(member: member)),
    );
    if (context.mounted) context.read<AdminMembersViewModel>().refresh();
  }

  Future<void> _confirmDelete(BuildContext ctx, String id, String name) async {
    final ext = ctx.athlos;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ext.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remover membro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        content: Text('Tem certeza que deseja remover $name?', style: TextStyle(fontSize: 13, color: ext.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text('Cancelar', style: TextStyle(color: ext.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Remover', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<AdminMembersViewModel>().removeMember(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminMembersViewModel>();
    final ext = context.athlos;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.surfaceColor, elevation: 0, automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: CircleAvatar(
            backgroundColor: ext.primaryColor.withOpacity(0.15),
            child: Text('AA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ext.primaryColor)),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Athlos Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          Text('GESTÃO DE MEMBROS', style: TextStyle(fontSize: 10, color: ext.textSecondary)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openRegisterMember,
              icon: const Icon(Icons.person_add, size: 13, color: Colors.white),
              label: const Text('Novo Membro', style: TextStyle(fontSize: 11, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ext.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ext.borderColor),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Membros da atlética', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          Text('${vm.members.length} membros', style: TextStyle(fontSize: 12, color: ext.textSecondary)),
        ]),
        const SizedBox(height: 12),

        // Busca + Filtro de status
        Row(children: [
          Expanded(child: AthlosTextField(
            hint: 'Buscar membro...',
            onChanged: (v) => context.read<AdminMembersViewModel>().setSearchQuery(v),
          )),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) => context.read<AdminMembersViewModel>().setStatusFilter(v),
            color: ext.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: ext.borderColor),
            ),
            itemBuilder: (_) => AdminMembersViewModel.statusFilters
                .map((f) => PopupMenuItem(
                      value: f,
                      child: Text(f, style: TextStyle(fontSize: 13, color: ext.textPrimary)),
                    ))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: ext.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ext.borderColor),
              ),
              child: Row(children: [
                Text(vm.statusFilter, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, size: 14, color: ext.textSecondary),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),

        if (vm.members.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Nenhum membro encontrado.', style: TextStyle(fontSize: 13, color: ext.textSecondary)),
            ),
          ),

        ...vm.members.map((m) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ext.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: m.isPresident
                  ? ext.primaryColor.withOpacity(0.5)
                  : ext.borderColor,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              AthlosAvatar(name: m.name, size: 40),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(m.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary), overflow: TextOverflow.ellipsis)),
                  if (m.isPresident) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(4)),
                      child: const Text('PRES', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(m.role, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
                if (m.email.isNotEmpty)
                  Text(m.email, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
              ])),
              StatusBadge(label: m.status),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _openEditMember(m),
                icon: Icon(Icons.edit_outlined, size: 13, color: ext.primaryColor),
                label: Text('Editar', style: TextStyle(fontSize: 12, color: ext.primaryColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: ext.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  minimumSize: Size.zero,
                ),
              )),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, m.id, m.name),
                icon: const Icon(Icons.delete_outline, size: 13, color: Color(0xFFEF4444)),
                label: const Text('Remover', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ]),
          ]),
        )).toList(),
      ]),
    );
  }
}
