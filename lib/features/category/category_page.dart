import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';
import 'package:yusuf_yemek/features/restaurant/restaurant_detail_page.dart';
import 'package:yusuf_yemek/models/restaurant_model.dart';

class CategoryPage extends StatefulWidget {
  final String categoryName;
  // DÜZELTME: Ana sepet artık bu sayfada yönetilmeyecek, başlangıç için boş olacak
  const CategoryPage({ super.key, required this.categoryName });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // Sepet, state içinde yerel olarak yönetiliyor
  final List<CartItem> _shoppingCart = [];

  // DÜZELTME: Veri yapısı, tek ve doğru olan yeni Restaurant modeline göre güncellendi
  final List<Restaurant> _allRestaurants = [
    Restaurant(
      name: 'Kebap Salonu',
      imageUrl: 'https://loremflickr.com/320/240/kebab,restaurant/all',
      category: 'Et',
      rating: 4.8, 
      deliveryTime: '25-35 dk',
      menu: [
        MenuItem(name: 'Adana Kebap', description: 'Acılı Adana kebap', price: 250.0, imageUrl: 'https://loremflickr.com/320/240/adana_kebab'),
        MenuItem(name: 'Urfa Kebap', description: 'Acısız Urfa kebap', price: 240.0, imageUrl: 'https://loremflickr.com/320/240/urfa_kebab'),
      ]
    ),
    Restaurant(
      name: 'Burger House',
      imageUrl: 'https://loremflickr.com/320/240/burger,place/all',
      category: 'FastFood',
      rating: 4.6, 
      deliveryTime: '20-30 dk',
      menu: [
        MenuItem(name: 'Hamburger', description: 'Ev yapımı burger', price: 180.0, imageUrl: 'https://loremflickr.com/320/240/burger'),
        MenuItem(name: 'Cheeseburger', description: 'Peynirli burger', price: 190.0, imageUrl: 'https://loremflickr.com/320/240/cheeseburger'),
      ]
    ),
     Restaurant(
      name: 'Pizza Time',
      imageUrl: 'https://loremflickr.com/320/240/pizza,restaurant/all',
      category: 'FastFood',
      rating: 4.7, 
      deliveryTime: '25-35 dk',
      menu: [
        MenuItem(name: 'Karışık Pizza', description: 'Bol malzemeli', price: 220.0, imageUrl: 'https://loremflickr.com/320/240/pizza'),
      ]
    ),
  ];

  late List<Restaurant> _restaurantsForCategory;

  @override
  void initState() {
    super.initState();
    // Kategoriye göre restoranları filtrele
    _restaurantsForCategory = _allRestaurants.where((r) => r.category == widget.categoryName).toList();
  }

  void _navigateToRestaurant(Restaurant restaurant) async {
    // RestaurantDetailPage'e giderken mevcut sepeti gönder ve dönüşte güncel sepeti al
    final updatedCart = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(
        builder: (context) => RestaurantDetailPage(
          restaurant: restaurant,
          shoppingCart: _shoppingCart, // Bu sayfanın sepetini gönder
        ),
      ),
    );

    if (updatedCart != null) {
      setState(() {
        _shoppingCart.clear();
        _shoppingCart.addAll(updatedCart);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: _restaurantsForCategory.isEmpty
          ? _buildEmptyView()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75, // Yükseklik / Genişlik oranı
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _restaurantsForCategory.length,
              itemBuilder: (context, index) {
                final restaurant = _restaurantsForCategory[index];
                return _buildRestaurantCard(restaurant);
              },
            ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bu kategoride henüz restoran bulunmuyor.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return GestureDetector(
      onTap: () => _navigateToRestaurant(restaurant),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: CachedNetworkImage(
                imageUrl: restaurant.imageUrl, // Ana restoran resmini kullan
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(restaurant.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
