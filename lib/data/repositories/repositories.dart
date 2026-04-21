import 'package:athlos/data/models/models.dart';


// ─── Feed Repository ──────────────────────────────────────────────────────────
class FeedRepository {
  static const List<PostModel> _posts = [
    PostModel(
      id: '1', category: 'PRESIDÊNCIA', categoryColor: 0xFF2563EB,
      title: 'Informamos que a assembleia geral foi reagendada para a próxima sexta-feira de 18:00 no auditório principal.',
      timeAgo: '2h atrás', likes: 12, comments: 3,
    ),
    PostModel(
      id: '2', category: 'TREINO', categoryColor: 0xFF10B981,
      title: 'Circuito de alta intensidade disponível na pista 2 hoje à tarde. Foco em explosão e resistência.',
      timeAgo: '4h atrás', likes: 28, comments: 7, hasImage: true,
    ),
    PostModel(
      id: '3', category: 'COMPETIÇÃO', categoryColor: 0xFFF59E0B,
      title: 'Confira o chaveamento das semifinais do torneio inter-clubes. Boa sorte a todos os atletas!',
      timeAgo: '1d atrás', likes: 45, comments: 18,
    ),
    PostModel(
      id: '4', category: 'AVISO', categoryColor: 0xFFEF4444,
      title: 'Novo Regulamento de Treinos: Temporada 2026. Leitura obrigatória para todos os atletas.',
      timeAgo: '2d atrás', likes: 67, comments: 22,
    ),
  ];

  List<PostModel> getPosts({String filter = 'RECENTES'}) {
    if (filter == 'RECENTES') return _posts;
    return _posts.where((p) => p.category == filter).toList();
  }
}

// ─── Product Repository ───────────────────────────────────────────────────────
class ProductRepository {
  final List<ProductModel> _products = [
    const ProductModel(id: '1', name: 'Performance Tech Tee', price: 149.90, tag: 'T-Shirts'),
    const ProductModel(id: '2', name: 'Stealth Pro Hoodie', price: 289.90, tag: 'Hoodies'),
    const ProductModel(id: '3', name: 'Vented Aero Shorts', price: 119.90, tag: 'Shorts'),
    const ProductModel(id: '4', name: 'Kinetic Elite Socks', price: 45.90, tag: 'Acessórios'),
    const ProductModel(id: '5', name: 'Casaco Atlética', price: 85.00, tag: 'Hoodies'),
    const ProductModel(id: '6', name: 'Apex Field Shorts', price: 59.06, tag: 'Shorts'),
  ];

  List<ProductModel> getProducts({String category = 'All Items'}) {
    if (category == 'All Items') return _products;
    return _products.where((p) => p.tag == category).toList();
  }

  double get totalRevenue => 42900.0;
  int get totalSales => 84;
}

// ─── Event Repository ─────────────────────────────────────────────────────────
class EventRepository {
  static const List<EventModel> _events = [
    EventModel(
      id: '1', date: 'JUN 14', type: 'TREINO', typeColor: 0xFF10B981,
      title: 'TREINO DE FUTEBOL',
      time: '19:00 – 21:00', place: 'Campo de Treinamento Alpha',
      bgColor: 0xFF1E3A5F,
    ),
    EventModel(
      id: '2', date: 'JUN 18', type: 'EVENTO SOCIAL', typeColor: 0xFFF59E0B,
      title: 'FESTA DA ATLÉTICA',
      time: '22:00 – 04:00', place: 'Club Hype – Setor Sul',
      bgColor: 0xFF3A1E5F,
    ),
    EventModel(
      id: '3', date: 'JUN 22', type: 'COMPETIÇÃO', typeColor: 0xFFEF4444,
      title: 'INTER-ATLÉTICAS 2024',
      time: '08:00 – 18:00', place: 'Ginásio Poliesportivo Central',
      bgColor: 0xFF1E3A2F,
    ),
  ];

  List<EventModel> getEvents({String filter = 'Todo'}) {
    if (filter == 'Todo') return _events;
    final map = {'Treinos': 'TREINO', 'Eventos': 'EVENTO SOCIAL', 'Competições': 'COMPETIÇÃO'};
    return _events.where((e) => e.type == (map[filter] ?? filter)).toList();
  }
}

// ─── Member Repository ────────────────────────────────────────────────────────
class MemberRepository {
  final List<MemberModel> _members = [
    const MemberModel(id: '1', rank: 1, name: 'Gabriel Breier', role: 'PRESIDENTE', status: 'ATIVO', isPresident: true),
    const MemberModel(id: '2', rank: 2, name: 'Rita Lee', role: 'VICE-PRESIDENTE', status: 'ATIVO'),
    const MemberModel(id: '3', rank: 3, name: 'Lucas Oliveira', role: 'FINANCEIRO', status: 'ATIVO'),
    const MemberModel(id: '4', rank: 4, name: 'Mariana Costa', role: 'MARKETING', status: 'ATIVO'),
    const MemberModel(id: '5', rank: 5, name: 'Ricardo Silva', role: 'DIRETOR', status: 'ATIVO'),
    const MemberModel(id: '6', rank: 24, name: 'Você (Gustavo)', role: 'MEMBRO COMUM', status: 'ATIVO', isCurrentUser: true),
    // Admin members
    const MemberModel(id: '7', rank: 1, name: 'Jordan Alexander', role: 'ADMIN', status: 'ATIVO', isAdmin: true),
    const MemberModel(id: '8', rank: 2, name: 'Sarah Chan', role: 'MEMBRO', status: 'ATIVO'),
    const MemberModel(id: '9', rank: 3, name: 'Marcus Rodriguez', role: 'MEMBRO', status: 'INATIVO'),
    const MemberModel(id: '10', rank: 4, name: 'Elena Motrova', role: 'MEMBRO', status: 'ATIVO'),
    const MemberModel(id: '11', rank: 5, name: 'David Thompson', role: 'MEMBRO', status: 'ATIVO'),
  ];

  List<MemberModel> getUserMembers() => _members.where((m) => !m.isAdmin).toList();
  List<MemberModel> getAdminMembers() => _members.where((m) => m.isAdmin || !m.isPresident).take(5).toList();

  void addMember(MemberModel member) => _members.add(member);
  void removeMember(String id) => _members.removeWhere((m) => m.id == id);
}

// ─── Agenda Repository ────────────────────────────────────────────────────────
class AgendaRepository {
  static const List<AgendaItemModel> _items = [
    AgendaItemModel(id: '1', title: 'Morning Strength & Conditioning', date: '04 Mai', type: 'Treino', typeColor: 0xFF10B981, hasImage: true),
    AgendaItemModel(id: '2', title: 'Morning Strength & Conditioning', date: '04 Mai', type: 'Treino', typeColor: 0xFF10B981),
    AgendaItemModel(id: '3', title: 'Inter-Atléticas 2025 – Abertura das Inscrições na Tarde', date: '06 Mai', type: 'Evento', typeColor: 0xFFF59E0B),
    AgendaItemModel(id: '4', title: 'Session End Awards Gala', date: '12 Mai', type: 'Social', typeColor: 0xFF8B5CF6, hasImage: true),
  ];

  List<AgendaItemModel> getItems() => _items;
}
