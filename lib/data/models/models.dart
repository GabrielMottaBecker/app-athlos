export 'auth_model.dart';
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

  const PostModel({
    required this.id,
    required this.category,
    required this.categoryColor,
    required this.title,
    required this.timeAgo,
    this.likes = 0,
    this.comments = 0,
    this.hasImage = false,
  });
}

// ─── Product Model ────────────────────────────────────────────────────────────
class ProductModel {
  final String id;
  final String name;
  final double price;
  final String tag;
  final bool inStock;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.tag,
    this.inStock = true,
  });
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
  final bool isAdmin;
  final bool isPresident;
  final bool isCurrentUser;
  final String senha;

  const MemberModel({
    required this.id,
    required this.rank,
    required this.name,
    required this.role,
    required this.status,
    this.email = '',
    this.ra = '',
    this.curso = '',
    this.isAdmin = false,
    this.isPresident = false,
    this.isCurrentUser = false,
    required this.senha,
  });

  MemberModel copyWith({
    String? name,
    String? role,
    String? status,
    String? email,
    String? ra,
    String? curso,
    String? senha,
  }) => MemberModel(
    id: id,
    rank: rank,
    name: name ?? this.name,
    role: role ?? this.role,
    status: status ?? this.status,
    email: email ?? this.email,
    ra: ra ?? this.ra,
    curso: curso ?? this.curso,
    isAdmin: isAdmin,
    isPresident: isPresident,
    isCurrentUser: isCurrentUser,
    senha: senha ?? this.senha,
  );
}

// ─── Atletica Model ───────────────────────────────────────────────────────────
class AtleticaModel {
  final String name;
  final String presidentName;
  final int primaryColorValue;
  final int backgroundColorValue;

  const AtleticaModel({
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
