import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/delivery_context.dart';
import 'models/auth_user.dart';
import 'services/local_auth_service.dart';

class Product {
  const Product(
    this.id,
    this.name,
    this.description,
    this.price,
    this.stock,
    this.category,
    this.featured,
    this.imagePath,
  );
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final bool featured;
  final String imagePath;
}

class CartItem {
  CartItem(
    this.product,
    this.quantity,
    this.color,
    this.packaging,
    this.message,
  );
  final Product product;
  int quantity;
  final String color;
  final String packaging;
  final String message;
  double get unitPrice => product.price + (packaging == 'Caja premium' ? 8 : 0);
  double get subtotal => unitPrice * quantity;
}

class ShopOrder {
  const ShopOrder(
    this.id,
    this.date,
    this.total,
    this.status,
    this.items,
    this.address,
    this.deliveryContext,
  );
  final String id;
  final DateTime date;
  final double total;
  final String status;
  final int items;
  final String address;
  final DeliveryContext deliveryContext;

  ShopOrder copyWith({DeliveryContext? deliveryContext}) => ShopOrder(
    id,
    date,
    total,
    status,
    items,
    address,
    deliveryContext ?? this.deliveryContext,
  );
}

class ShopState extends ChangeNotifier {
  late final SharedPreferences _storage;
  late final LocalAuthService _authService;
  bool authenticated = false;
  String userName = 'Marleyth';
  String userEmail = '';
  String role = 'cliente';
  int tab = 0;
  DeliveryContext deliveryContext = const DeliveryContext();

  final products = const [
    Product(
      'RE-01',
      'Girasol con Abuelita y Chocolates',
      'Detalle artesanal amarillo con girasol y rosas de satín, peluche de '
          'abuelita, chocolates en caja de corazón y envoltura decorativa. '
          'Ideal para cumpleaños, agradecimiento o Día de la Madre.',
      39.99,
      6,
      'Dulces y peluches',
      true,
      'assets/images/girasol_abuelita_chocolates.jpg',
    ),
    Product(
      'RE-02',
      'Ramo Princesa de Rosas Rojas',
      'Bouquet grande de rosas rojas de satín elaboradas a mano, envoltura '
          'negra de varias capas, mariposas doradas y cinta personalizada. '
          'Recomendado para aniversarios y celebraciones especiales.',
      54.99,
      4,
      'Ramos grandes',
      true,
      'assets/images/ramo_princesa_rojo.jpg',
    ),
    Product(
      'RE-03',
      'Ramo Corona Iluminada',
      'Rosas eternas rojas y amarilla central con iluminación LED cálida, '
          'corona dorada, mariposa decorativa, tarjeta y lazo rojo. '
          'Una opción llamativa para cumpleaños y homenajes.',
      32.99,
      8,
      'Con luces',
      true,
      'assets/images/ramo_corona_iluminada.jpg',
    ),
    Product(
      'RE-04',
      'Ramo Azul con Mariposa',
      'Bouquet compacto de rosas azules de satín con perlas, mariposa dorada, '
          'portatarjeta de corazón y envoltura estilo periódico. Adecuado '
          'para graduaciones, amistad o detalles personalizados.',
      21.99,
      10,
      'Detalles',
      false,
      'assets/images/ramo_azul_mariposa.jpg',
    ),
    Product(
      'RE-05',
      'Ramo Reina con Oso',
      'Arreglo premium de rosas rojas y amarilla de satín, corona, mariposa '
          'dorada, perlas y oso de peluche grande. Diseñado para cumpleaños, '
          'aniversarios y regalos de alto impacto.',
      49.99,
      3,
      'Dulces y peluches',
      true,
      'assets/images/ramo_reina_oso.jpg',
    ),
    Product(
      'RE-06',
      'Ramo Tiara Romántica',
      'Detalle minimalista con rosas rojas de satín, tiara plateada, '
          'mariposa dorada, tarjeta personalizada y lazo negro con perlas. '
          'Ideal para aniversarios o celebraciones de pareja.',
      18.99,
      12,
      'Detalles',
      false,
      'assets/images/ramo_tiara_romantica.jpg',
    ),
    Product(
      'RE-07',
      'Ramo I Love You',
      'Bouquet abundante de rosas rojas de satín con perlas, mariposa dorada, '
          'cinta I LOVE YOU y tarjeta dedicatoria. Recomendado para '
          'aniversarios, San Valentín o declaraciones especiales.',
      37.99,
      7,
      'Aniversario',
      true,
      'assets/images/ramo_i_love_you.jpg',
    ),
  ];
  final List<CartItem> cart = [];
  final List<ShopOrder> orders = [];
  final Set<String> favorites = {};

  int get cartCount => cart.fold(0, (value, item) => value + item.quantity);
  double get subtotal => cart.fold(0, (value, item) => value + item.subtotal);
  double get delivery => cart.isEmpty || subtotal >= 75 ? 0 : 3.5;
  double get total => subtotal + delivery;

  Future<void> initialize() async {
    _storage = await SharedPreferences.getInstance();
    _authService = LocalAuthService(_storage);
    await _authService.seedDemoUsers();
    _restoreUser(_authService.restoredSession());
    favorites.addAll(_storage.getStringList('favorites') ?? []);
    final contextStored = _storage.getString('delivery_context');
    if (contextStored != null) {
      deliveryContext = DeliveryContext.fromJson(
        jsonDecode(contextStored) as Map<String, dynamic>,
      );
    }
    final stored = _storage.getString('orders');
    if (stored != null) {
      for (final value in jsonDecode(stored) as List<dynamic>) {
        final map = value as Map<String, dynamic>;
        orders.add(
          ShopOrder(
            map['id'] as String,
            DateTime.parse(map['date'] as String),
            (map['total'] as num).toDouble(),
            map['status'] as String,
            map['items'] as int,
            map['address'] as String,
            DeliveryContext.fromJson(
              (map['deliveryContext'] as Map<String, dynamic>?) ?? const {},
            ),
          ),
        );
      }
    }
  }

  Future<String?> login(String email, String password) async {
    final user = await _authService.signIn(email, password);
    if (user == null) return 'Correo o contraseña incorrectos.';
    _restoreUser(user);
    notifyListeners();
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    final error = await _authService.register(
      name: name,
      email: email,
      password: password,
    );
    if (error != null) return error;
    final user = _authService.restoredSession();
    _restoreUser(user);
    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    authenticated = false;
    userEmail = '';
    tab = 0;
    await _authService.signOut();
    notifyListeners();
  }

  void _restoreUser(AuthUser? user) {
    authenticated = user != null;
    userName = user?.name ?? 'Marleyth';
    userEmail = user?.email ?? '';
    role = user?.role ?? 'cliente';
  }

  void setTab(int value) {
    tab = value;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    await _storage.setStringList('favorites', favorites.toList());
    notifyListeners();
  }

  void add(
    Product product,
    int quantity,
    String color,
    String packaging,
    String message,
  ) {
    cart.add(CartItem(product, quantity, color, packaging, message));
    notifyListeners();
  }

  void changeQuantity(CartItem item, int value) {
    if (value <= 0) {
      cart.remove(item);
    } else {
      item.quantity = value.clamp(1, item.product.stock);
    }
    notifyListeners();
  }

  Future<void> updateDeliveryContext(DeliveryContext context) async {
    deliveryContext = context.copyWith(updatedAt: DateTime.now());
    await _storage.setString(
      'delivery_context',
      jsonEncode(deliveryContext.toJson()),
    );
    notifyListeners();
  }

  Future<void> markOrderCapabilitySynced(String orderId) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return;
    orders[index] = orders[index].copyWith(
      deliveryContext: orders[index].deliveryContext.copyWith(
        syncPending: false,
      ),
    );
    await _persistOrders();
    notifyListeners();
  }

  Future<ShopOrder> checkout(String address) async {
    final order = ShopOrder(
      'RE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      DateTime.now(),
      total,
      'Confirmado',
      cartCount,
      address,
      deliveryContext.copyWith(syncPending: true),
    );
    orders.insert(0, order);
    cart.clear();
    await _persistOrders();
    notifyListeners();
    return order;
  }

  Future<void> _persistOrders() => _storage.setString(
    'orders',
    jsonEncode(
      orders
          .map(
            (order) => {
              'id': order.id,
              'date': order.date.toIso8601String(),
              'total': order.total,
              'status': order.status,
              'items': order.items,
              'address': order.address,
              'deliveryContext': order.deliveryContext.toJson(),
            },
          )
          .toList(),
    ),
  );
}
