import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/datasources/loja_remote_datasource.dart';
import '../data/datasources/token_local_datasource.dart';
import '../data/models/models.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'productId':   product.id,
    'productName': product.name,
    'price':       product.price,
    'tag':         product.tag,
    'imagePath':   product.imagePath,
    'status':      product.status,
    'description': product.description,
    'estoque':     product.estoque,
    'quantity':    quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: ProductModel(
      id:          json['productId'] as String,
      name:        json['productName'] as String,
      price:       (json['price'] as num).toDouble(),
      tag:         json['tag'] as String? ?? 'Geral',
      imagePath:   json['imagePath'] as String?,
      status:      json['status'] as String? ?? 'DISPONIVEL',
      description: json['description'] as String? ?? '',
      estoque:     (json['estoque'] as num?)?.toInt() ?? 0,
    ),
    quantity: (json['quantity'] as num).toInt(),
  );
}

// ─── Loja (usuário) ───────────────────────────────────────────────────────────
class LojaViewModel extends ChangeNotifier {
  static const _cartKey = 'cart_items';

  final LojaRemoteDatasource _ds = LojaRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _activeCategory = 'All Items';
  List<ProductModel> _products = [];
  final List<CartItem> _cart = [];
  bool _isLoading = false;

  String get activeCategory => _activeCategory;
  bool get isLoading => _isLoading;

  List<ProductModel> get products {
    if (_activeCategory == 'All Items') return _products;
    return _products.where((p) => p.tag == _activeCategory).toList();
  }

  List<CartItem> get cart => _cart;
  double get totalRevenue => 0.0;
  int get totalSales => 0;

  int get cartCount => _cart.fold(0, (sum, i) => sum + i.quantity);
  double get cartTotal => _cart.fold(0.0, (sum, i) => sum + i.subtotal);

  static const List<String> categories = [
    'All Items', 'T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'
  ];

  LojaViewModel() {
    _loadCartFromStorage();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) return;
      _products = await _ds.getProdutos(atleticaId);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _activeCategory = category;
    notifyListeners();
  }

  int quantityInCart(String productId) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    return idx >= 0 ? _cart[idx].quantity : 0;
  }

  bool canAddMore(ProductModel product) {
    final qty = quantityInCart(product.id);
    return product.estoque <= 0 ? false : qty < product.estoque;
  }

  void addToCart(ProductModel product) {
    if (!canAddMore(product)) return;
    final idx = _cart.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _cart[idx].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
    _saveCartToStorage();
    notifyListeners();
  }

  void decrementCart(String productId) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (_cart[idx].quantity > 1) {
      _cart[idx].quantity--;
    } else {
      _cart.removeAt(idx);
    }
    _saveCartToStorage();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((i) => i.product.id == productId);
    _saveCartToStorage();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _saveCartToStorage();
    notifyListeners();
  }

  String get whatsappMessage {
    final lines = _cart.map((i) =>
      '• ${i.quantity}x ${i.product.name} — R\$ ${i.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
    ).join('\n');
    final total = cartTotal.toStringAsFixed(2).replaceAll('.', ',');
    return 'Olá! Gostaria de fazer o seguinte pedido:\n\n$lines\n\n*Total: R\$ $total*\n\nAguardo o retorno para combinar a entrega!';
  }

  Future<void> _saveCartToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cart.map((i) => i.toJson()).toList());
      await prefs.setString(_cartKey, encoded);
    } catch (_) {}
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List;
        _cart.clear();
        _cart.addAll(decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)));
        notifyListeners();
      }
    } catch (_) {}
  }
}

// ─── Admin Loja ───────────────────────────────────────────────────────────────
class AdminLojaViewModel extends ChangeNotifier {
  final LojaRemoteDatasource _ds = LojaRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();

  String _activeCategory = 'All Products';
  List<ProductModel> _products = [];
  bool _isLoading = false;

  String get activeCategory => _activeCategory;
  bool get isLoading => _isLoading;
  double get totalRevenue => 0.0;
  int get totalSales => 0;

  List<ProductModel> get products {
    if (_activeCategory == 'All Products') return _products;
    return _products.where((p) => p.tag == _activeCategory).toList();
  }

  static const List<String> categories = [
    'All Products', 'T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'
  ];

  AdminLojaViewModel() {
    load();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final atleticaId = await _tokenDs.getAtleticaId();
      if (atleticaId == null) return;
      _products = await _ds.getProdutos(atleticaId);
    } catch (_) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> inativarProduto(String id) async {
    await _ds.changeStatus(id, 'INATIVO');
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _products[idx] = _products[idx].copyWith(status: 'INATIVO');
      notifyListeners();
    }
  }

  void setCategory(String cat) {
    _activeCategory = cat;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void removeProduct(String id) => inativarProduto(id);
  void addProduct(ProductModel p) {}
  void updateProduct(ProductModel p) {}
}

// ─── Cadastrar / Editar Produto ───────────────────────────────────────────────
class RegisterProductViewModel extends ChangeNotifier {
  final LojaRemoteDatasource _ds = LojaRemoteDatasource();
  final TokenLocalDatasource _tokenDs = TokenLocalDatasource();
  final _picker = ImagePicker();
  final ProductModel? initialProduct;

  String _selectedCategory = 'T-Shirts';
  bool _isLoading = false;
  XFile? _image;

  static const List<String> categories = [
    'T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'
  ];

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isEditMode => initialProduct != null;
  XFile? get selectedImage => _image;

  RegisterProductViewModel({this.initialProduct}) {
    if (initialProduct != null) {
      _selectedCategory = initialProduct!.tag;
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final img = await _picker.pickImage(source: source, imageQuality: 80);
    if (img != null) {
      _image = img;
      notifyListeners();
    }
  }

  void removeImage() {
    _image = null;
    notifyListeners();
  }

  Future<bool> save({
    required String name,
    required String price,
    required String description,
    required String estoque,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final parsedPrice = double.tryParse(price.replaceAll(',', '.')) ?? 0.0;
      final parsedEstoque = int.tryParse(estoque) ?? 0;

      if (isEditMode) {
        final body = {
          'nome':      name.trim(),
          'descricao': description.trim(),
          'preco':     parsedPrice,
          'estoque':   parsedEstoque,
        };
        await _ds.updateProduto(initialProduct!.id, body);
      } else {
        final atleticaId = await _tokenDs.getAtleticaId();
        final body = {
          'nome':       name.trim(),
          'descricao':  description.trim(),
          'preco':      parsedPrice,
          'estoque':    parsedEstoque,
          'atleticaId': atleticaId,
        };
        await _ds.createProduto(body);
      }
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('>>> ERRO save produto: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
