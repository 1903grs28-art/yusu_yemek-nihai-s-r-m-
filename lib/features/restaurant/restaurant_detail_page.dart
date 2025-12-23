import 'package:flutter/material.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';
import 'package:yusuf_yemek/features/cart/cart_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yusuf_yemek/models/restaurant_model.dart'; // Yeni model importu

class RestaurantDetailPage extends StatefulWidget {
  final Restaurant restaurant;
  final List<CartItem> shoppingCart;

  const RestaurantDetailPage({
    super.key,
    required this.restaurant,
    required this.shoppingCart,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late List<CartItem> _shoppingCart;

  @override
  void initState() {
    super.initState();
    _shoppingCart = List.from(widget.shoppingCart);
  }

  void _addToCart(MenuItem item) {
    setState(() {
      final existingItemIndex = _shoppingCart.indexWhere((cartItem) => cartItem.name == item.name);

      if (existingItemIndex != -1) {
        _shoppingCart[existingItemIndex].quantity++;
      } else {
        _shoppingCart.add(CartItem(
          name: item.name,
          price: item.price,
          quantity: 1,
          imageUrl: item.imageUrl,
        ));
      }
    });
  }

  // DÜZENLEME: Sepetten ürün çıkaran veya miktarını azaltan fonksiyon
  void _removeFromCart(MenuItem item) {
    setState(() {
      final existingItemIndex = _shoppingCart.indexWhere((cartItem) => cartItem.name == item.name);

      if (existingItemIndex != -1) {
        if (_shoppingCart[existingItemIndex].quantity > 1) {
          _shoppingCart[existingItemIndex].quantity--;
        } else {
          _shoppingCart.removeAt(existingItemIndex);
        }
      }
    });
  }

  int get _totalItemsInCart => _shoppingCart.fold(0, (sum, item) => sum + item.quantity);

  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_shoppingCart);
    return true;
  }

  void _goToCart() async {
    final result = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(builder: (context) => CartPage(cartItems: _shoppingCart)),
    );
    if (result != null) {
      setState(() {
        _shoppingCart = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.restaurant.name)),
        body: ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: widget.restaurant.menu.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final item = widget.restaurant.menu[index];
            // DÜZENLEME: Sepetteki ürünü ve miktarını bulmak için yeni mantık
            final cartItem = _shoppingCart.firstWhere((cartItem) => cartItem.name == item.name, orElse: () => CartItem(name: '', price: 0, quantity: 0));
            final bool isAdded = cartItem.quantity > 0;

            return Card(
              elevation: 0,
              color: Colors.transparent,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(imageUrl: item.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        Text(item.description, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('${item.price.toStringAsFixed(2)} TL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // DÜZENLEME: Ekle/Çıkar butonu grubu
                  isAdded
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 28),
                            onPressed: () => _removeFromCart(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(cartItem.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
                            onPressed: () => _addToCart(item),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () => _addToCart(item),
                        child: const Text('Ekle'),
                      ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: _totalItemsInCart > 0 ? FloatingActionButton.extended(
          onPressed: _goToCart,
          label: Text('Sepete Git ($_totalItemsInCart)'),
          icon: const Icon(Icons.shopping_cart),
        ) : null,
      ),
    );
  }
}
