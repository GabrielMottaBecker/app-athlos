// ─── Post Model ───────────────────────────────────────────────────────────────
class PostModel {
  final String id;
  final String category;
  final int categoryColor;
  final String title;
  final String timeAgo;
  final int likes;
  final int comments;
  final bool hasImage;
  final String? imagePath;

  const PostModel({
    required this.id,
    required this.category,
    required this.categoryColor,
    required this.title,
    required this.timeAgo,
    this.likes = 0,
    this.comments = 0,
    this.hasImage = false,
    this.imagePath,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    const colorMap = {
      'PRESIDÊNCIA': 0xFF2563EB,
      'TREINO':      0xFF10B981,
      'COMPETIÇÃO':  0xFFF59E0B,
      'AVISO':       0xFFEF4444,
      'EVENTO':      0xFFF59E0B,
      'EXTRA':       0xFF8B5CF6,
    };
    final category = (json['type'] as String? ?? 'AVISO').toUpperCase();
    return PostModel(
      id:            json['id'] as String,
      category:      category,
      categoryColor: colorMap[category] ?? 0xFF2563EB,
      title:         json['title'] as String? ?? '',
      timeAgo:       _timeAgo(json['createdAt'] as String?),
      likes:         0,
      comments:      0,
      hasImage:      false,
    );
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    final diff = DateTime.now().difference(DateTime.parse(iso));
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24)   return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  /// Serializa o model para persistência local (cache).
  /// Diferente do formato cru da API: aqui já guardamos os campos
  /// derivados (timeAgo, categoryColor) prontos para exibição.
  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'categoryColor': categoryColor,
    'title': title,
    'timeAgo': timeAgo,
    'likes': likes,
    'comments': comments,
    'hasImage': hasImage,
    'imagePath': imagePath,
  };

  /// Reconstrói o model a partir do cache local (formato de [toJson]).
  factory PostModel.fromCacheJson(Map<String, dynamic> json) => PostModel(
    id: json['id'] as String,
    category: json['category'] as String,
    categoryColor: json['categoryColor'] as int,
    title: json['title'] as String,
    timeAgo: json['timeAgo'] as String,
    likes: json['likes'] as int? ?? 0,
    comments: json['comments'] as int? ?? 0,
    hasImage: json['hasImage'] as bool? ?? false,
    imagePath: json['imagePath'] as String?,
  );

  PostModel copyWith({
    String? category,
    int? categoryColor,
    String? title,
    String? timeAgo,
    int? likes,
    int? comments,
    bool? hasImage,
    Object? imagePath = _sentinel,
  }) => PostModel(
    id: id,
    category: category ?? this.category,
    categoryColor: categoryColor ?? this.categoryColor,
    title: title ?? this.title,
    timeAgo: timeAgo ?? this.timeAgo,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    hasImage: hasImage ?? this.hasImage,
    imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
  );
}

// sentinel para distinguir null explícito de "não informado"
const Object _sentinel = Object();

// ─── Product Model ────────────────────────────────────────────────────────────
class ProductModel {
  final String id;
  final String name;
  final double price;
  final String tag;
  final String? imagePath;
  final String status;
  final String description;   
  final int estoque;          

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.tag,
    this.imagePath,
    this.status = 'DISPONIVEL',
    this.description = '',
    this.estoque = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id:          json['id'] as String,
      name:        json['nome'] as String? ?? '',
      price:       (json['preco'] as num?)?.toDouble() ?? 0.0,
      tag:         json['categoria'] as String? ?? 'Geral',
      imagePath:   json['imagemUrl'] as String?,
      status:      json['status'] as String? ?? 'DISPONIVEL',
      description: json['descricao'] as String? ?? '',
      estoque:     (json['estoque'] as num?)?.toInt() ?? 0,
    );
  }

  ProductModel copyWith({
    String? name,
    double? price,
    String? tag,
    Object? imagePath = _sentinel,
    String? status,
    String? description,
    int? estoque,
  }) => ProductModel(
    id:          id,
    name:        name ?? this.name,
    price:       price ?? this.price,
    tag:         tag ?? this.tag,
    imagePath:   imagePath == _sentinel ? this.imagePath : imagePath as String?,
    status:      status ?? this.status,
    description: description ?? this.description,
    estoque:     estoque ?? this.estoque,
  );
}

// ─── Event Model ──────────────────────────────────────────────────────────────
class EventModel {
  final String id;
  final String date;
  final String type;
  final int typeColor;
  final String title;
  final String time;
  final String place;
  final int bgColor;

  const EventModel({
    required this.id,
    required this.date,
    required this.type,
    required this.typeColor,
    required this.title,
    required this.time,
    required this.place,
    required this.bgColor,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    const typeColors = {
      'TREINO':        0xFF10B981,
      'EVENTO SOCIAL': 0xFFF59E0B,
      'EVENTO':        0xFFF59E0B,
      'COMPETIÇÃO':    0xFFEF4444,
      'EXTRAS':        0xFF8B5CF6,
      'EXTRA':         0xFF8B5CF6,
    };
    const bgColors = {
      'TREINO':        0xFF1E3A5F,
      'EVENTO SOCIAL': 0xFF3A1E5F,
      'EVENTO':        0xFF3A1E5F,
      'COMPETIÇÃO':    0xFF1E3A2F,
      'EXTRAS':        0xFF2E1E5F,
      'EXTRA':         0xFF2E1E5F,
    };
    final type = (json['type'] as String? ?? 'EVENTO').toUpperCase();
    return EventModel(
      id:        json['id'] as String,
      date:      json['date'] as String? ?? '',
      type:      type,
      typeColor: typeColors[type] ?? 0xFF10B981,
      title:     json['title'] as String? ?? '',
      time:      json['time'] as String? ?? '',
      place:     json['place'] as String? ?? '',
      bgColor:   bgColors[type] ?? 0xFF1E3A5F,
    );
  }
}

// ─── Member Model ─────────────────────────────────────────────────────────────
class MemberModel {
  final String id;
  final int rank;
  final String name;
  final String role;
  final String status;
  final String email;
  final String ra;
  final String curso;
  final String senha;
  final String telefone;

  const MemberModel({
    required this.id,
    required this.rank,
    required this.name,
    required this.role,
    required this.status,
    required this.email,
    required this.ra,
    required this.curso,
    required this.senha,
    this.telefone = '',
  });

  // Getters derivados do role — sem campos extras
  bool get isPresident => role.toUpperCase() == 'PRESIDENTE';
  bool get isAdmin     => role.toUpperCase() == 'ADMINISTRADOR' || role.toUpperCase() == 'ADMIN';
  bool get isCurrentUser => false; // será implementado via userId do token futuramente

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id:       json['id'] as String,
      rank:     0,
      name:     json['nome'] as String? ?? '',
      role:     json['cargo']?['nome'] as String? ?? 'MEMBRO',
      status:   json['status'] as String? ?? 'ATIVO',
      email:    json['email'] as String? ?? '',
      ra:       json['documento'] as String? ?? '',
      // 'curso' não existe no backend (tabela associados não tem essa coluna);
      // permanece vazio até que o conceito seja persistido no schema/DTO.
      curso:    json['curso'] as String? ?? '',
      senha:    '',
      telefone: json['telefone'] as String? ?? '',
    );
  }

  MemberModel copyWith({
    String? name,
    String? role,
    String? status,
    String? email,
    String? ra,
    String? curso,
    String? senha,
    String? telefone,
  }) => MemberModel(
    id:       id,
    rank:     rank,
    name:     name ?? this.name,
    role:     role ?? this.role,
    status:   status ?? this.status,
    email:    email ?? this.email,
    ra:       ra ?? this.ra,
    curso:    curso ?? this.curso,
    senha:    senha ?? this.senha,
    telefone: telefone ?? this.telefone,
  );
}

// ─── Atletica Model ───────────────────────────────────────────────────────────
class AtleticaModel {
  final String id;
  final String name;
  final String presidentName;
  final int primaryColorValue;
  final int backgroundColorValue;

  const AtleticaModel({
    required this.id,
    required this.name,
    required this.presidentName,
    required this.primaryColorValue,
    required this.backgroundColorValue,
  });
}

// ─── Agenda Item Model ────────────────────────────────────────────────────────
class AgendaItemModel {
  final String id;
  final String title;
  final String date;
  final String type;
  final int typeColor;
  final bool hasImage;

  const AgendaItemModel({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.typeColor,
    this.hasImage = false,
  });
}