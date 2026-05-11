import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.price * quantity;
}

class LojaViewModel extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();

  String _activeCategory = 'All Items';
  List<ProductModel> _products = [];
  final List<CartItem> _cart = [];

  String get activeCategory => _activeCategory;
  List<ProductModel> get products => _products;
  List<CartItem> get cart => _cart;
  double get totalRevenue => _repo.totalRevenue;
  int get totalSales => _repo.totalSales;

  int get cartCount => _cart.fold(0, (sum, i) => sum + i.quantity);
  double get cartTotal => _cart.fold(0.0, (sum, i) => sum + i.subtotal);

  static const List<String> categories = ['All Items', 'T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'];

  LojaViewModel() {
    _loadProducts();
  }

  void _loadProducts() {
    _products = _repo.getProducts(category: _activeCategory);
    notifyListeners();
  }

  void setCategory(String category) {
    _activeCategory = category;
    _loadProducts();
  }

  int quantityInCart(String productId) {
    final idx = _cart.indexWhere((i) => i.product.id == productId);
    return idx >= 0 ? _cart[idx].quantity : 0;
  }

  void addToCart(ProductModel product) {
    final idx = _cart.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _cart[idx].quantity++;
    } else {
      _cart.add(CartItem(product: product));
    }
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
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  String get whatsappMessage {
    final lines = _cart.map((i) =>
      '• ${i.quantity}x ${i.product.name} — R\$ ${i.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
    ).join('\n');
    final total = cartTotal.toStringAsFixed(2).replaceAll('.', ',');
    return 'Olá! Gostaria de fazer o seguinte pedido:\n\n$lines\n\n*Total: R\$ $total*\n\nAguardo o retorno para combinar a entrega!';
  }
}

class AdminLojaViewModel extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();
  String _activeCategory = 'All Products';
  List<ProductModel> _products = [];

  String get activeCategory => _activeCategory;
  List<ProductModel> get products => _products;
  double get totalRevenue => _repo.totalRevenue;
  int get totalSales => _repo.totalSales;

  static const List<String> categories = ['All Products', 'T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'];

  AdminLojaViewModel() {
    _loadProducts();
  }

  void _loadProducts() {
    _products = _repo.getProducts(category: _activeCategory);
    notifyListeners();
  }

  void setCategory(String cat) {
    _activeCategory = cat;
    _loadProducts();
  }

  void addProduct(ProductModel p) {
    _repo.addProduct(p);
    _loadProducts();
  }

  void updateProduct(ProductModel p) {
    _repo.updateProduct(p);
    _loadProducts();
  }

  void removeProduct(String id) {
    _repo.removeProduct(id);
    _loadProducts();
  }

  void refresh() => _loadProducts();
}

class RegisterProductViewModel extends ChangeNotifier {
  final ProductRepository _repo = ProductRepository();
  final _picker = ImagePicker();
  final ProductModel? initialProduct;

  String _selectedCategory = 'T-Shirts';
  bool _isLoading = false;
  XFile? _image;

  static const List<String> categories = ['T-Shirts', 'Hoodies', 'Shorts', 'Acessórios'];

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isEditMode => initialProduct != null;
  XFile? get selectedImage => _image;

  RegisterProductViewModel({this.initialProduct}) {
    if (initialProduct != null) {
      _selectedCategory = initialProduct!.tag;
      if (initialProduct!.imagePath != null) {
        _image = XFile(initialProduct!.imagePath!);
      }
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

  Future<bool> save({required String name, required String price}) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    final parsedPrice = double.tryParse(price.replaceAll(',', '.')) ?? 0.0;

    if (isEditMode) {
      _repo.updateProduct(initialProduct!.copyWith(
        name: name.trim(),
        price: parsedPrice,
        tag: _selectedCategory,
        imagePath: _image?.path,
      ));
    } else {
      _repo.addProduct(ProductModel(
        id: _repo.nextId,
        name: name.trim(),
        price: parsedPrice,
        tag: _selectedCategory,
        imagePath: _image?.path,
      ));
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }
}
