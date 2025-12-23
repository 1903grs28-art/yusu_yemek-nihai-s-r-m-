import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';
import 'package:yusuf_yemek/features/checkout/delivery_details_page.dart';

class CartPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CartPage({super.key, required this.cartItems});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<CartItem> _currentCartItems;

  @override
  void initState() {
    super.initState();
    // Gelen sepetin değiştirilebilir bir kopyasını oluştur
    _currentCartItems = List.from(widget.cartItems);
  }

  void _increaseQuantity(int index) {
    setState(() {
      _currentCartItems[index].quantity++;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (_currentCartItems[index].quantity > 1) {
        _currentCartItems[index].quantity--;
      } else {
        // Miktar 1 iken azaltmaya basılırsa ürünü tamamen kaldır
        _removeItemFromCart(index);
      }
    });
  }

  void _removeItemFromCart(int index) {
    setState(() {
      _currentCartItems.removeAt(index);
    });
  }

  double _calculateTotal() {
    if (_currentCartItems.isEmpty) {
      return 0.0;
    }
    return _currentCartItems
        .map((item) => item.price * item.quantity)
        .reduce((value, element) => value + element);
  }
  
  // Geri tuşuna basıldığında güncel sepeti bir önceki sayfaya döndür
  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_currentCartItems);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calculateTotal();

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Sepetim'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_currentCartItems),
          ),
        ),
        body: _currentCartItems.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Sepetiniz boş', style: TextStyle(fontSize: 20, color: Colors.grey)),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _currentCartItems.length,
          itemBuilder: (context, index) {
            final item = _currentCartItems[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl != null
                          ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 70, height: 70, fit: BoxFit.cover)
                          : Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('${item.price.toStringAsFixed(2)} TL', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // DÜZENLEME: Miktar artırma/azaltma butonları
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 28),
                          onPressed: () => _decreaseQuantity(index),
                        ),
                        Text(item.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
                          onPressed: () => _increaseQuantity(index),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _currentCartItems.isEmpty
            ? null
            : Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryDetailsPage(
                    cartItems: _currentCartItems,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Siparişi Onayla (${total.toStringAsFixed(2)} TL)'),
          ),
        ),
      ),
    );
  }
}
