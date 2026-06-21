import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_notifier.dart';
import '../../viewmodels/viewmodels.dart';
import '../shared/widgets/widgets.dart';
import '../auth/login_view.dart';
import '../../data/datasources/token_local_datasource.dart';

class UserMainView extends StatefulWidget {
  const UserMainView({super.key});

  @override
  State<UserMainView> createState() => _UserMainViewState();
}

class _UserMainViewState extends State<UserMainView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    final tabs = const [
      FeedView(), LojaView(), AgendaView(), ParticipantesView(), PerfilView(),
    ];
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      body: tabs[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ext.surfaceColor, border: Border(top: BorderSide(color: ext.borderColor))),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: ext.surfaceColor,
          selectedItemColor: ext.primaryColor,
          unselectedItemColor: ext.textSecondary.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedFontSize: 10, unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Início'),
            BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Loja'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Agenda'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Membros'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

// ─── Shared User AppBar ───────────────────────────────────────────────────────
class _UserAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  const _UserAppBar({this.actions});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  State<_UserAppBar> createState() => _UserAppBarState();
}

class _UserAppBarState extends State<_UserAppBar> {
  late final NotificacoesViewModel _notifVm;

  @override
  void initState() {
    super.initState();
    _notifVm = NotificacoesViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifVm.load());
  }

  @override
  void dispose() {
    _notifVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    final themeNotifier = context.watch<ThemeNotifier>();
    final nomeAtletica = themeNotifier.nomeAtletica;
    final logoUrl = themeNotifier.logoUrl;

    return ChangeNotifierProvider.value(
      value: _notifVm,
      child: Builder(builder: (ctx) {
        final notifVm = ctx.watch<NotificacoesViewModel>();
        return AppBar(
          backgroundColor: ext.surfaceColor, elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: logoUrl != null && logoUrl.isNotEmpty
                ? Image.network(
                    logoUrl,
                    width: 28, height: 28, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackIcon(ext),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(width: 28, height: 28, color: ext.surfaceVariant);
                    },
                  )
                : _fallbackIcon(ext),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(nomeAtletica.toUpperCase(), overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ext.textPrimary, letterSpacing: 2)),
            ),
          ]),
          actions: widget.actions ?? [
            IconButton(
              icon: Icon(Icons.search, color: ext.textSecondary, size: 22),
              onPressed: () {},
            ),
            Stack(children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: ext.textSecondary, size: 22),
                onPressed: () => _openNotificacoes(ctx, notifVm, ext),
              ),
              if (notifVm.naoLidas > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), shape: BoxShape.circle),
                    child: Center(child: Text(
                      notifVm.naoLidas > 9 ? '9+' : '${notifVm.naoLidas}',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                    )),
                  ),
                ),
            ]),
          ],
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: ext.borderColor)),
        );
      }),
    );
  }

  Widget _fallbackIcon(AthlosThemeExtension ext) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(6)),
    child: const Icon(Icons.sports, color: Colors.white, size: 16),
  );

  void _openNotificacoes(BuildContext context, NotificacoesViewModel vm, AthlosThemeExtension ext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _NotificacoesSheet(ext: ext),
      ),
    );
  }
}

// ─── Notificações Sheet ───────────────────────────────────────────────────────
class _NotificacoesSheet extends StatelessWidget {
  final AthlosThemeExtension ext;
  const _NotificacoesSheet({required this.ext});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificacoesViewModel>();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: ext.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: ext.borderColor, borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(children: [
              Text('Notificações', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ext.textPrimary)),
              if (vm.naoLidas > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
                  child: Text('${vm.naoLidas}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
              const Spacer(),
              if (vm.naoLidas > 0)
                TextButton(
                  onPressed: () => vm.marcarTodasComoLidas(),
                  child: Text('Marcar todas', style: TextStyle(fontSize: 12, color: ext.primaryColor)),
                ),
            ]),
          ),
          Divider(color: ext.borderColor, height: 1),
          // Lista
          Expanded(
            child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.notificacoes.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none, size: 48, color: ext.textSecondary.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('Nenhuma notificação', style: TextStyle(fontSize: 14, color: ext.textSecondary)),
                  ]))
                : ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: vm.notificacoes.length,
                    separatorBuilder: (_, __) => Divider(color: ext.borderColor, height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final n = vm.notificacoes[i];
                      final lida = n['lida'] as bool? ?? false;
                      return InkWell(
                        onTap: lida ? null : () => vm.marcarComoLida(n['id'] as String),
                        child: Container(
                          color: lida ? Colors.transparent : ext.primaryColor.withOpacity(0.05),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: lida ? ext.surfaceVariant : ext.primaryColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_outlined, size: 18,
                                color: lida ? ext.textSecondary : ext.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (n['titulo'] != null)
                                Text(n['titulo'] as String,
                                  style: TextStyle(fontSize: 13, fontWeight: lida ? FontWeight.w400 : FontWeight.w600, color: ext.textPrimary)),
                              if (n['mensagem'] != null)
                                Text(n['mensagem'] as String,
                                  style: TextStyle(fontSize: 12, color: ext.textSecondary, height: 1.4)),
                            ])),
                            if (!lida)
                              Container(width: 8, height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Feed View ────────────────────────────────────────────────────────────────
class FeedView extends StatefulWidget {
  const FeedView({super.key});
  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late final FeedViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = FeedViewModel();
    // Carrega após o primeiro frame, garantindo que o token já existe
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
      child: const _FeedContent(),
    );
  }
}

class _FeedContent extends StatelessWidget {
  const _FeedContent();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: _UserAppBar(),
      body: Column(children: [
        // Banner destaque
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [ext.primaryColor, ext.primaryColor.withBlue(220)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
              child: const Text('AVISO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),
            const Text('Novo Regulamento de Treinos:\nTemporada 2026.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
            const SizedBox(height: 6),
            Text('Confira as atualizações obrigatórias a partir d...',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), height: 1.4)),
          ]),
        ),
        // Filtros
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: FilterChipRow(
            filters: FeedViewModel.filters,
            activeFilter: vm.activeFilter,
            onSelect: (f) => context.read<FeedViewModel>().setFilter(f),
          ),
        ),
        // Lista de posts
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: vm.filteredPosts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _PostCard(post: vm.filteredPosts[i]),
        )),
      ]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final post;
  const _PostCard({required this.post});
  @override
  Widget build(BuildContext context) {
    final ext = context.athlos;
    final categoryColor = Color(post.categoryColor as int);
    return AthlosCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AthlosAvatar(name: post.category, size: 30),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.category, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ext.textPrimary)),
            Text(post.timeAgo, style: TextStyle(fontSize: 10, color: ext.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: categoryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(post.category, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: categoryColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(post.title, style: TextStyle(fontSize: 13, color: ext.textPrimary, height: 1.45)),
        if (post.hasImage) ...[
          const SizedBox(height: 10),
          Container(height: 90,
            decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Icon(Icons.image_outlined, size: 28, color: ext.textSecondary.withOpacity(0.4)))),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.thumb_up_outlined, size: 14, color: ext.textSecondary),
          const SizedBox(width: 4),
          Text('${post.likes}', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
          const SizedBox(width: 14),
          Icon(Icons.comment_outlined, size: 14, color: ext.textSecondary),
          const SizedBox(width: 4),
          Text('${post.comments}', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
          const Spacer(),
          Icon(Icons.share_outlined, size: 14, color: ext.textSecondary),
        ]),
      ]),
    );
  }
}

// ─── Loja View ────────────────────────────────────────────────────────────────
class LojaView extends StatefulWidget {
  const LojaView({super.key});
  @override
  State<LojaView> createState() => _LojaViewState();
}

class _LojaViewState extends State<LojaView> {
  late final LojaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = LojaViewModel();
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
      child: const _LojaContent(),
    );
  }
}

class _LojaContent extends StatelessWidget {
  const _LojaContent();

  static const _whatsappNumber = '5545999596814';

  Future<void> _openWhatsApp(String message) async {
    final url = Uri.parse('https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showCart(BuildContext context) {
    final vm = context.read<LojaViewModel>();
    final ext = context.athlos;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _CartBottomSheet(onWhatsApp: _openWhatsApp),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LojaViewModel>();
    final ext = context.athlos;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: _UserAppBar(),
      body: Stack(children: [
        ListView(children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0), height: 130,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ext.primaryColor.withOpacity(0.9), Colors.black87]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Text('COLEÇÃO 2026',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FilterChipRow(
              filters: LojaViewModel.categories,
              activeFilter: vm.activeCategory,
              onSelect: (c) => context.read<LojaViewModel>().setCategory(c),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.76,
              children: vm.products.map((p) {
                final qty = vm.quantityInCart(p.id);
                return Container(
                  decoration: BoxDecoration(
                    color: ext.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: qty > 0 ? ext.primaryColor.withOpacity(0.4) : ext.borderColor),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Stack(children: [
                      Container(
                        decoration: BoxDecoration(
                          color: ext.surfaceVariant,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(child: Icon(Icons.checkroom_outlined, size: 44, color: ext.textSecondary.withOpacity(0.3))),
                      ),
                      if (qty > 0)
                        Positioned(top: 8, right: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(10)),
                          child: Text('$qty', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        )),
                    ])),
                    Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ext.textPrimary), maxLines: 2),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('R\$ ${p.price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ext.primaryColor)),
                        if (qty == 0)
                          GestureDetector(
                            onTap: () => context.read<LojaViewModel>().addToCart(p),
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.add, size: 14, color: Colors.white),
                            ),
                          )
                        else
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            GestureDetector(
                              onTap: () => context.read<LojaViewModel>().decrementCart(p.id),
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: BorderRadius.circular(6), border: Border.all(color: ext.borderColor)),
                                child: Icon(Icons.remove, size: 12, color: ext.textPrimary),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text('$qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ext.textPrimary)),
                            ),
                            GestureDetector(
                              onTap: () => context.read<LojaViewModel>().addToCart(p),
                              child: Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(6)),
                                child: const Icon(Icons.add, size: 12, color: Colors.white),
                              ),
                            ),
                          ]),
                      ]),
                    ])),
                  ]),
                );
              }).toList(),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('LOYALTY PROGRAM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              const Text('ATHLOS PRIME', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Get early access and free shipping on all orders.', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: Text('LEARN MORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ext.primaryColor))),
            ]),
          ),
          const SizedBox(height: 80),
        ]),

        // Barra flutuante do carrinho
        if (vm.cartCount > 0)
          Positioned(
            left: 16, right: 16, bottom: 16,
            child: GestureDetector(
              onTap: () => _showCart(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: ext.primaryColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: ext.primaryColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text('${vm.cartCount}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Ver carrinho', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
                  Text('R\$ ${vm.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

class _CartBottomSheet extends StatelessWidget {
  final Future<void> Function(String) onWhatsApp;
  const _CartBottomSheet({required this.onWhatsApp});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LojaViewModel>();
    final ext = context.athlos;

    return Container(
      decoration: BoxDecoration(
        color: ext.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: ext.borderColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          Text('Seu Pedido', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          const Spacer(),
          TextButton(
            onPressed: () {
              vm.clearCart();
              Navigator.pop(context);
            },
            child: Text('Limpar', style: TextStyle(fontSize: 12, color: ext.textSecondary)),
          ),
        ]),
        const SizedBox(height: 8),
        ...vm.cart.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.checkroom_outlined, size: 20, color: ext.textSecondary.withOpacity(0.4)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.product.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ext.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('R\$ ${item.product.price.toStringAsFixed(2)} un.', style: TextStyle(fontSize: 11, color: ext.textSecondary)),
            ])),
            Row(children: [
              GestureDetector(
                onTap: () => vm.decrementCart(item.product.id),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: ext.surfaceVariant, borderRadius: BorderRadius.circular(6), border: Border.all(color: ext.borderColor)),
                  child: Icon(Icons.remove, size: 13, color: ext.textPrimary),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('${item.quantity}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ext.textPrimary)),
              ),
              GestureDetector(
                onTap: () => vm.addToCart(item.product),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.add, size: 13, color: Colors.white),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Text('R\$ ${item.subtotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ext.primaryColor)),
          ]),
        )),
        const SizedBox(height: 8),
        Divider(color: ext.borderColor),
        const SizedBox(height: 8),
        Row(children: [
          Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ext.textPrimary)),
          const Spacer(),
          Text('R\$ ${vm.cartTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ext.primaryColor)),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            await onWhatsApp(vm.whatsappMessage);
          },
          icon: const Icon(Icons.chat_outlined, size: 18, color: Colors.white),
          label: const Text('Falar no WhatsApp', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )),
      ]),
    );
  }
}

// ─── Agenda View ──────────────────────────────────────────────────────────────
class AgendaView extends StatefulWidget {
  const AgendaView({super.key});
  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  late final AgendaViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AgendaViewModel();
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
      child: const _AgendaContent(),
    );
  }
}

class _AgendaContent extends StatelessWidget {
  const _AgendaContent();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AgendaViewModel>();
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.surfaceColor, elevation: 0, automaticallyImplyLeading: false,
        title: Text('Agenda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Text('Fique por dentro dos seus compromissos.', style: TextStyle(fontSize: 12, color: ext.textSecondary))),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilterChipRow(
            filters: AgendaViewModel.filters, activeFilter: vm.activeFilter,
            onSelect: (f) => context.read<AgendaViewModel>().setFilter(f),
          )),
        const SizedBox(height: 14),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: vm.events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final e = vm.events[i];
            final typeColor = Color(e.typeColor);
            return Container(
              decoration: BoxDecoration(color: Color(e.bgColor), borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: typeColor.withOpacity(0.25), borderRadius: BorderRadius.circular(4)),
                      child: Text(e.type, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: typeColor))),
                    const Spacer(),
                    Text(e.date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ])),
                Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Text(e.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1))),
                Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(children: [const Icon(Icons.access_time, size: 12, color: Colors.white60), const SizedBox(width: 4),
                    Text(e.time, style: const TextStyle(fontSize: 11, color: Colors.white60))])),
                Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Colors.white60), const SizedBox(width: 4),
                    Expanded(child: Text(e.place, style: const TextStyle(fontSize: 11, color: Colors.white60)))])),
                Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<AgendaViewModel>().confirmPresence(e.id),
                      icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                      label: const Text('Confirmar Presença', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: ext.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    ))),
              ]),
            );
          },
        )),
      ]),
    );
  }
}

// ─── Participantes View ───────────────────────────────────────────────────────
// ─── Participantes View ───────────────────────────────────────────────────────
class ParticipantesView extends StatefulWidget {
  const ParticipantesView({super.key});
  @override
  State<ParticipantesView> createState() => _ParticipantesViewState();
}

class _ParticipantesViewState extends State<ParticipantesView> {
  late final ParticipantesViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ParticipantesViewModel();
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
      child: const _ParticipantesContent(),
    );
  }
}

class _ParticipantesContent extends StatelessWidget {
  const _ParticipantesContent();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ParticipantesViewModel>();
    final ext = context.athlos;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: AppBar(
        backgroundColor: ext.surfaceColor, elevation: 0, automaticallyImplyLeading: false,
        title: Text('Participantes da Atlética', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ext.textPrimary)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: ext.borderColor)),
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: AthlosTextField(
            hint: 'Buscar participante...',
            onChanged: (v) => context.read<ParticipantesViewModel>().setSearchQuery(v),
          )),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: vm.members.length,
          itemBuilder: (_, i) {
            final m = vm.members[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: m.isPresident ? ext.primaryColor : ext.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: m.isCurrentUser ? ext.primaryColor : ext.borderColor, width: m.isCurrentUser ? 1.5 : 1),
              ),
              child: Row(children: [
                SizedBox(width: 28, child: Text('${m.rank}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: m.isPresident ? Colors.white : ext.textSecondary))),
                AthlosAvatar(name: m.name, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (m.isPresident) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Presidente', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white))),
                  Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: m.isPresident ? Colors.white : ext.textPrimary)),
                  Text(m.role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: m.isPresident ? Colors.white70 : ext.textSecondary)),
                ])),
                if (m.isCurrentUser) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: ext.primaryColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('Você', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ext.primaryColor))),
              ]),
            );
          },
        )),
      ]),
    );
  }
}

// ─── Perfil View ──────────────────────────────────────────────────────────────
class PerfilView extends StatefulWidget {
  const PerfilView({super.key});
  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  late final PerfilViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = PerfilViewModel();
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
      child: const _PerfilContent(),
    );
  }
}

class _PerfilContent extends StatefulWidget {
  const _PerfilContent();
  @override
  State<_PerfilContent> createState() => _PerfilContentState();
}

class _PerfilContentState extends State<_PerfilContent> {

  void _showPerfilModal(PerfilViewModel vm, AthlosThemeExtension ext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: ext.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(color: ext.borderColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(width: 64, height: 64,
            decoration: BoxDecoration(
              color: ext.primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: ext.primaryColor, width: 2),
            ),
            child: Center(child: Text(vm.initials,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.primaryColor)))),
          const SizedBox(height: 12),
          Text(vm.nome.isEmpty ? 'Usuário' : vm.nome,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ext.textPrimary)),
          const SizedBox(height: 4),
          Text(vm.email, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: ext.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Text(vm.cargo,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ext.primaryColor))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ext.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ext.borderColor),
            ),
            child: Column(children: [
              _InfoRow(label: 'Nome',   value: vm.nome,  ext: ext),
              Divider(color: ext.borderColor, height: 20),
              _InfoRow(label: 'E-mail', value: vm.email, ext: ext),
              Divider(color: ext.borderColor, height: 20),
              _InfoRow(label: 'Cargo',  value: vm.cargo, ext: ext),
              Divider(color: ext.borderColor, height: 20),
              _InfoRow(label: 'Perfil', value: vm.role,  ext: ext),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ext.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Fechar', style: TextStyle(fontSize: 14, color: ext.textSecondary)),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<PerfilViewModel>();
    final ext = context.athlos;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ext.backgroundColor,
      appBar: _UserAppBar(),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              Container(
                color: ext.surfaceColor, padding: const EdgeInsets.all(20),
                child: Column(children: [
                  InkWell(
                    onTap: () => _showPerfilModal(vm, ext),
                    borderRadius: BorderRadius.circular(40),
                    child: Stack(children: [
                      Container(width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: ext.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: ext.primaryColor, width: 2.5),
                        ),
                        child: Center(child: Text(vm.initials,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ext.primaryColor)))),
                      Positioned(bottom: 0, right: 0, child: Container(width: 24, height: 24,
                        decoration: BoxDecoration(color: ext.primaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, color: Colors.white, size: 12))),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text(vm.nome.isEmpty ? 'Usuário' : vm.nome,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ext.textPrimary)),
                  const SizedBox(height: 4),
                  if (vm.email.isNotEmpty)
                    Text(vm.email, style: TextStyle(fontSize: 12, color: ext.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: ext.primaryColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(vm.cargo,
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500))),
                ]),
              ),
              const SizedBox(height: 8),
              _PerfilSection(title: 'ADMINISTRAÇÃO', ext: ext, items: [
                _PerfilItem(
                  icon: Icons.people_outline,
                  label: 'Gestão de Associados',
                  ext: ext,
                  onTap: () => _showPerfilModal(vm, ext),
                ),
                _PerfilItem(
                  icon: Icons.payment_outlined,
                  label: 'Meus Pagamentos',
                  ext: ext,
                ),
                _PerfilItem(
                  icon: Icons.settings_outlined,
                  label: 'Configurações da Conta',
                  ext: ext,
                  onTap: () => _showPerfilModal(vm, ext),
                ),
              ]),
              const SizedBox(height: 8),
              _PerfilSection(title: 'SESSÃO', ext: ext, items: [
                _PerfilItem(
                  icon: Icons.logout,
                  label: 'Sair da Conta',
                  ext: ext,
                  isDestructive: true,
                  onTap: () async {
                    await TokenLocalDatasource().clearTokens();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginView()),
                      (r) => false,
                    );
                  },
                ),
              ]),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => _showPerfilModal(vm, ext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ext.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Configurações',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 80),
            ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final AthlosThemeExtension ext;
  const _InfoRow({required this.label, required this.value, required this.ext});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: ext.textSecondary))),
    Flexible(child: Text(value.isEmpty ? '—' : value,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.textPrimary),
      textAlign: TextAlign.right)),
  ]);
}

class _PerfilSection extends StatelessWidget {
  final String title; final List<Widget> items; final AthlosThemeExtension ext;
  const _PerfilSection({required this.title, required this.items, required this.ext});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ext.textSecondary, letterSpacing: 0.8))),
    Container(margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: ext.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: ext.borderColor)),
      child: Column(children: items.asMap().entries.map((e) => Column(children: [
        e.value,
        if (e.key < items.length - 1) Divider(height: 1, color: ext.borderColor, indent: 16, endIndent: 16),
      ])).toList())),
  ]);
}

class _PerfilItem extends StatelessWidget {
  final IconData icon; final String label; final AthlosThemeExtension ext;
  final bool isDestructive; final VoidCallback? onTap;
  const _PerfilItem({required this.icon, required this.label, required this.ext, this.isDestructive = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFEF4444) : ext.textPrimary;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              color: isDestructive ? const Color(0xFFEF4444).withOpacity(0.1) : ext.surfaceVariant,
              borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, size: 18, color: ext.textSecondary.withOpacity(0.5)),
        ])));
  }
}