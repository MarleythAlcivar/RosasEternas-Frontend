import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'api_service.dart';
import 'models/delivery_context.dart';
import 'screens/auth_screen.dart';
import 'services/capability_service.dart';
import 'shop_state.dart';

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Rosas Eternas',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9D2348),
        surface: const Color(0xFFFFFBFC),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFBFC),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: Color(0xFFE8DDE1)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    ),
    home: Consumer<ShopState>(
      builder: (_, state, _) =>
          state.authenticated ? const ShopShell() : const LoginScreen(),
    ),
  );
}

class ShopShell extends StatelessWidget {
  const ShopShell({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    const pages = [
      HomeScreen(),
      CatalogScreen(),
      CartScreen(),
      OrdersScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: state.tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.tab,
        onDestinationSelected: state.setTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: state.cartCount > 0,
              label: Text('${state.cartCount}'),
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Carrito',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Pedidos',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final featured = state.products.where((item) => item.featured).toList();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rosas Eternas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              'Hola, ${state.userName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 210,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        state.products[1].imagePath,
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xD050102A), Color(0x0050102A)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 190,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Un detalle que permanece',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Arreglos destacados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => state.setTab(1),
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: ApiStatusCard(),
            ),
          ),
          ProductGrid(products: featured),
        ],
      ),
    );
  }
}

/// A visible, repeatable proof that the mobile client can reach the API.
class ApiStatusCard extends StatefulWidget {
  const ApiStatusCard({super.key});

  @override
  State<ApiStatusCard> createState() => _ApiStatusCardState();
}

class _ApiStatusCardState extends State<ApiStatusCard> {
  late Future<ApiHealth> _health = ApiService().health();

  void _retry() {
    // Create the Future before setState. The callback itself must remain
    // synchronous; returning the Future triggers FlutterError.
    final nextHealth = ApiService().health();
    setState(() {
      _health = nextHealth;
    });
  }

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF7F9),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: FutureBuilder<ApiHealth>(
        future: _health,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final ok = snapshot.hasData;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                loading
                    ? Icons.sync
                    : ok
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: ok
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loading
                          ? 'Comprobando API…'
                          : ok
                          ? 'API conectada correctamente'
                          : 'No fue posible conectar con la API',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ok
                          ? '${snapshot.data!.service} · ${snapshot.data!.message}'
                          : 'Inicia el backend y pulsa Reintentar. ${snapshot.error ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Reintentar solicitud a la API',
                onPressed: loading ? null : _retry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';
  String category = 'Todos';
  @override
  Widget build(BuildContext context) {
    final products = context.watch<ShopState>().products;
    final categories = [
      'Todos',
      ...{for (final p in products) p.category},
    ];
    final filtered = products
        .where(
          (p) =>
              (category == 'Todos' || p.category == category) &&
              p.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Buscar arreglos',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ChoiceChip(
                  label: Text(categories[index]),
                  selected: category == categories[index],
                  onSelected: (_) =>
                      setState(() => category = categories[index]),
                ),
              ),
            ),
          ),
          ProductGrid(products: filtered),
        ],
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products});
  final List<Product> products;
  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    sliver: SliverGrid.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: .72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) => ProductCard(product: products[index]),
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});
  final Product product;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    final favorite = state.favorites.contains(product.id);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: product.id,
                    child: Image.asset(product.imagePath, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton.filledTonal(
                      tooltip: 'Favorito',
                      onPressed: () => state.toggleFavorite(product.id),
                      icon: Icon(
                        favorite ? Icons.favorite : Icons.favorite_border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  String color = 'Rojo';
  String packaging = 'Caja clásica';
  final message = TextEditingController();
  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final unit = product.price + (packaging == 'Caja premium' ? 8 : 0);
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Hero(
              tag: product.id,
              child: Image.asset(product.imagePath, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '\$${unit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Precio referencial en USD. Puede variar según personalización.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Text(product.description),
                Text(
                  '${product.stock} unidades disponibles',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                Text(
                  'Color de rosas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Wrap(
                  spacing: 8,
                  children: ['Rojo', 'Rosa', 'Marfil', 'Vino']
                      .map(
                        (value) => ChoiceChip(
                          label: Text(value),
                          selected: color == value,
                          onSelected: (_) => setState(() => color = value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: packaging,
                  decoration: const InputDecoration(labelText: 'Empaque'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Caja clásica',
                      child: Text('Caja clásica - incluida'),
                    ),
                    DropdownMenuItem(
                      value: 'Caja premium',
                      child: Text('Caja premium - +\$8.00'),
                    ),
                  ],
                  onChanged: (value) => setState(() => packaging = value!),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: message,
                  maxLength: 120,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje de la tarjeta',
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Cantidad',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton.outlined(
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text('$quantity', textAlign: TextAlign.center),
                    ),
                    IconButton.outlined(
                      onPressed: quantity < product.stock
                          ? () => setState(() => quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              context.read<ShopState>().add(
                product,
                quantity,
                color,
                packaging,
                message.text.trim(),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: Text('Agregar · \$${(unit * quantity).toStringAsFixed(2)}'),
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tu carrito',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: state.cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64),
                  const SizedBox(height: 12),
                  const Text('Tu carrito está vacío'),
                  FilledButton.tonal(
                    onPressed: () => state.setTab(1),
                    child: const Text('Ver catálogo'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 170),
              itemCount: state.cart.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final item = state.cart[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.product.imagePath,
                            width: 82,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${item.color} · ${item.packaging}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  state.changeQuantity(item, item.quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () =>
                                  state.changeQuantity(item, item.quantity - 1),
                              icon: Icon(
                                item.quantity == 1
                                    ? Icons.delete_outline
                                    : Icons.remove_circle_outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomSheet: state.cart.isEmpty
          ? null
          : SafeArea(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TotalRow('Subtotal', state.subtotal),
                    TotalRow('Entrega', state.delivery),
                    const Divider(),
                    TotalRow('Total', state.total, bold: true),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        ),
                        child: const Text('Continuar al pago'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class TotalRow extends StatelessWidget {
  const TotalRow(this.label, this.amount, {super.key, this.bold = false});
  final String label;
  final double amount;
  final bool bold;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)),
      const Spacer(),
      Text(
        amount == 0 && label == 'Entrega'
            ? 'Gratis'
            : '\$${amount.toStringAsFixed(2)}',
      ),
    ],
  );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final address = TextEditingController(text: 'Av. Principal 123, Puyo');
  String payment = 'Tarjeta';
  bool processing = false;
  final CapabilityService _capabilities = CapabilityService();
  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  Future<void> pay() async {
    if (address.text.trim().length < 8) return;
    setState(() => processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final shop = context.read<ShopState>();
    final order = await shop.checkout(address.text.trim());
    try {
      await ApiService().sendDeliveryCapability(
        orderId: order.id,
        context: order.deliveryContext.toJson(),
      );
      await shop.markOrderCapabilitySynced(order.id);
    } catch (_) {
      // The local order remains available if the local API is offline.
    }
    if (!mounted) return;
    Navigator.pop(context);
    context.read<ShopState>().setTab(3);
  }

  Future<bool> _explain({required String title, required String body}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _requestLocation() async {
    if (!await _explain(
      title: 'Usar ubicación aproximada',
      body:
          'Usaremos tu ubicación solo ahora para guardar una referencia aproximada de entrega. También puedes escribir tu dirección.',
    )) {
      return;
    }
    final result = await _capabilities.requestDeliveryLocation();
    if (!mounted) return;
    final shop = context.read<ShopState>();
    await shop.updateDeliveryContext(
      shop.deliveryContext.copyWith(
        locationState: result.state,
        locationLabel: result.value,
        clearLocation: result.value == null,
      ),
    );
    if (!mounted) return;
    _handleResult(result, isLocation: true);
  }

  Future<void> _requestCamera() async {
    if (!await _explain(
      title: 'Adjuntar foto de referencia',
      body:
          'Abriremos la cámara para que adjuntes una foto opcional que ayude a preparar tu arreglo. No solicitamos acceso a tu galería.',
    )) {
      return;
    }
    final result = await _capabilities.requestReferencePhoto();
    if (!mounted) return;
    final shop = context.read<ShopState>();
    await shop.updateDeliveryContext(
      shop.deliveryContext.copyWith(
        cameraState: result.state,
        photoPath: result.value,
        clearPhoto: result.value == null,
      ),
    );
    if (!mounted) return;
    _handleResult(result, isLocation: false);
  }

  void _handleResult(CapabilityResult result, {required bool isLocation}) {
    String message;
    VoidCallback? action;
    String? actionLabel;
    if (result.state == CapabilityState.permanentlyDenied) {
      message =
          'Permiso bloqueado permanentemente. Actívalo desde Ajustes para usar esta opción.';
      actionLabel = 'Abrir ajustes';
      action = openAppSettings;
    } else if (result.state == CapabilityState.serviceDisabled) {
      message =
          'El servicio de ubicación está desactivado. Puedes activarlo o escribir la dirección.';
      actionLabel = 'Ubicación';
      action = Geolocator.openLocationSettings;
    } else if (result.state == CapabilityState.denied ||
        result.state == CapabilityState.restricted) {
      message =
          'Permiso no concedido. La compra continúa sin esta información opcional.';
    } else if (result.state == CapabilityState.failed) {
      message = result.message ?? 'No se pudo completar la operación.';
    } else if (result.state == CapabilityState.unavailable) {
      message = 'Esta capacidad no está disponible en este dispositivo.';
    } else {
      message =
          result.message ??
          (isLocation
              ? 'Ubicación aproximada guardada.'
              : 'Foto de referencia guardada localmente.');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action == null || actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: action),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Entrega y pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Dirección de entrega',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(controller: address, maxLines: 2),
          const SizedBox(height: 18),
          Text(
            'Opciones de entrega',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          _CapabilityTile(
            icon: Icons.my_location_outlined,
            title: 'Usar ubicación aproximada',
            subtitle: _locationText(state.deliveryContext),
            onTap: _requestLocation,
          ),
          _CapabilityTile(
            icon: Icons.camera_alt_outlined,
            title: 'Adjuntar foto de referencia',
            subtitle: _cameraText(state.deliveryContext),
            onTap: _requestCamera,
          ),
          const SizedBox(height: 18),
          Text(
            'Método de pago',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RadioGroup<String>(
            groupValue: payment,
            onChanged: (value) => setState(() => payment = value!),
            child: const Column(
              children: [
                RadioListTile(
                  value: 'Tarjeta',
                  title: Text('Tarjeta'),
                  subtitle: Text('Pago simulado para demostración'),
                ),
                RadioListTile(
                  value: 'Transferencia',
                  title: Text('Transferencia bancaria'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Total a pagar'),
                  const Spacer(),
                  Text(
                    '\$${state.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: processing ? null : pay,
            icon: const Icon(Icons.lock_outline),
            label: Text(processing ? 'Procesando...' : 'Confirmar pedido'),
          ),
          const Text(
            'Esta versión no procesa dinero real ni almacena datos bancarios.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _locationText(DeliveryContext context) =>
      switch (context.locationState) {
        CapabilityState.granted =>
          context.locationLabel ??
              'Permiso concedido; sin referencia guardada.',
        CapabilityState.permanentlyDenied =>
          'Permiso bloqueado. Toca para abrir Ajustes.',
        CapabilityState.serviceDisabled =>
          'Servicio apagado. Toca para configurarlo.',
        CapabilityState.denied || CapabilityState.restricted =>
          'No concedida. La dirección manual sigue disponible.',
        CapabilityState.failed =>
          'No disponible temporalmente. Usa la dirección manual.',
        _ => 'Opcional. Se solicita solo al tocar esta opción.',
      };

  String _cameraText(DeliveryContext context) => switch (context.cameraState) {
    CapabilityState.granted =>
      context.hasPhoto
          ? 'Foto guardada localmente.'
          : 'Permiso concedido; sin foto adjunta.',
    CapabilityState.permanentlyDenied =>
      'Permiso bloqueado. Toca para abrir Ajustes.',
    CapabilityState.denied ||
    CapabilityState.restricted => 'No concedida. Puedes continuar sin foto.',
    CapabilityState.failed =>
      'No disponible temporalmente. Puedes continuar sin foto.',
    _ => 'Opcional. No se solicita permiso de galería.',
  };
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<ShopState>().orders;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis pedidos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Aún no tienes pedidos.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final order = orders[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Pedido ${order.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Chip(label: Text(order.status)),
                          ],
                        ),
                        Text(
                          '${order.items} producto(s) · \$${order.total.toStringAsFixed(2)}',
                        ),
                        Text(
                          order.address,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        const LinearProgressIndicator(value: .45),
                        const SizedBox(height: 4),
                        const Text(
                          'Confirmado · Preparación iniciada',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<ShopState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi cuenta',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              state.userName.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            state.userName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            state.userEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            state.role,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 22),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Favoritos'),
                  trailing: Text('${state.favorites.length}'),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text('Direcciones'),
                  trailing: Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.support_agent),
                  title: Text('Ayuda y contacto'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          if (state.role == 'administrador') ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Panel de administración'),
                subtitle: Text(
                  '${state.products.length} productos · ${state.orders.length} pedidos',
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: state.logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Rosas Eternas v1.0.0 · Prototipo académico',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
