import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:yusuf_yemek/models/user_model.dart' as model;
import 'package:yusuf_yemek/models/restaurant_model.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';
import 'package:yusuf_yemek/features/restaurant/restaurant_detail_page.dart';
import 'package:yusuf_yemek/features/tracking/track_order_page.dart';
import 'package:yusuf_yemek/features/auth/profile_page.dart';
import 'package:yusuf_yemek/features/category/category_page.dart';
import 'package:yusuf_yemek/features/cart/cart_page.dart';


// --- KATEGORİ MODELİ ---
class Category {
  final String name;
  final IconData icon;
  Category({required this.name, required this.icon});
}

// --- ANA SAYFA WIDGET'I (STATE MANAGEMENT İLE) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  model.User? _user;
  final List<CartItem> _shoppingCart = [];
  
  // DÜZENLEME: FutureBuilder için veri yükleme fonksiyonu
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // DÜZENLEME: Veri yükleme işlemi Future'a taşındı
    _initializationFuture = _initializeUser();
  }

  // DÜZENLEME: Sadece kullanıcı verisini yükleyen async fonksiyon
  Future<void> _initializeUser() async {
    final authUser = auth.FirebaseAuth.instance.currentUser;
    if (authUser != null) {
        _user = model.User(uid: authUser.uid, name: authUser.displayName ?? 'İsimsiz');
    }
    // Auth state değişikliklerini dinle
    auth.FirebaseAuth.instance.authStateChanges().listen((newUser) {
      if(mounted){
        setState(() {
          if (newUser == null) {
            _user = null;
          } else {
            _user = model.User(uid: newUser.uid, name: newUser.displayName ?? 'İsimsiz');
          }
        });
      }
    });
  }

  void _updateCart(List<CartItem> updatedCart) {
    setState(() {
      _shoppingCart.clear();
      _shoppingCart.addAll(updatedCart);
    });
  }

  void _handleLogout() {
    auth.FirebaseAuth.instance.signOut();
  }

  void _handleLoginSuccess(model.User loggedInUser) {
    setState(() {
      _user = loggedInUser;
    });
  }

  void _onItemTapped(int index) {
    if (index == 3) {
        _openCartPage();
        return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openCartPage() async {
    final result = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(builder: (context) => CartPage(cartItems: _shoppingCart)),
    );
    if (result != null) {
      _updateCart(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DÜZENLEME: FutureBuilder ile veri yükleme durumu kontrol ediliyor
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Veri yüklenirken siyah ekran yerine yükleniyor ikonu göster
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Veri yüklendikten sonra ana arayüzü çiz
        final totalItemsInCart = _shoppingCart.fold<int>(0, (sum, item) => sum + item.quantity);
        final pages = [
          HomePageContent(shoppingCart: _shoppingCart, onCartUpdated: _updateCart),
          const TrackOrderPage(),
          ProfilePage(user: _user, onLogout: _handleLogout, onLoginSuccess: _handleLoginSuccess),
        ];

        return Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
              const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Siparişlerim'),
              const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              BottomNavigationBarItem(
                icon: Badge(label: Text(totalItemsInCart.toString()), isLabelVisible: totalItemsInCart > 0, child: const Icon(Icons.shopping_cart)),
                label: 'Sepetim',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.red[800],
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}


// --- ANA SAYFANIN ASIL İÇERİĞİ (DEĞİŞİKLİK YOK) ---
class HomePageContent extends StatefulWidget {
  final List<CartItem> shoppingCart;
  final Function(List<CartItem>) onCartUpdated;

  const HomePageContent({super.key, required this.shoppingCart, required this.onCartUpdated});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  
  final List<Category> categories = [
    Category(name: 'Et', icon: Icons.kebab_dining),
    Category(name: 'Tavuk', icon: Icons.fastfood_outlined),
    Category(name: 'Tatlı', icon: Icons.cake_outlined),
    Category(name: 'Market', icon: Icons.store_mall_directory_outlined),
    Category(name: 'FastFood', icon: Icons.local_pizza_outlined),
    Category(name: 'Su', icon: Icons.water_drop_outlined),
  ];

  final List<String> adBanners = [
    'https://loremflickr.com/600/300/promotion,sale/all',
    'https://loremflickr.com/600/300/food,deal/all',
  ];

  final List<Restaurant> allRestaurants = [
    Restaurant(name: 'Kebap Salonu', imageUrl: 'https://loremflickr.com/320/240/kebab,restaurant/all', category: 'Et', rating: 4.8, deliveryTime: '25-35 dk', menu: [MenuItem(name: 'Adana Kebap', description: 'Acılı Adana kebap', price: 250.0, imageUrl: 'https://loremflickr.com/320/240/adana_kebab')]),
    Restaurant(name: 'Burger House', imageUrl: 'https://loremflickr.com/320/240/burger,place/all', category: 'FastFood', rating: 4.6, deliveryTime: '20-30 dk', menu: [MenuItem(name: 'Hamburger', description: 'Ev yapımı burger', price: 180.0, imageUrl: 'https://loremflickr.com/320/240/burger')]),
  ];

  void _navigateToCategory(String categoryName) async {
    final updatedCart = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(builder: (context) => CategoryPage(categoryName: categoryName))
    );
    if (updatedCart != null) {
      widget.onCartUpdated(updatedCart);
    }
  }

  void _navigateToRestaurant(Restaurant restaurant) async {
    final updatedCart = await Navigator.of(context).push<List<CartItem>>(
      MaterialPageRoute(builder: (context) => RestaurantDetailPage(
        restaurant: restaurant,
        shoppingCart: widget.shoppingCart, 
      )) 
    );
    if (updatedCart != null) {
      widget.onCartUpdated(updatedCart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildSectionTitle('Kategoriler'),
          _buildCategoryFilters(),
          _buildSectionTitle('Kampanyalar'),
          _buildAdBanners(),
          _buildSectionTitle('Restoranlar'),
          _buildVerticalRestaurantList(allRestaurants),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.red.shade700,
      pinned: true,
      expandedHeight: 130.0,
      flexibleSpace: const FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 65),
        title: Text('Hoş geldiniz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        centerTitle: false,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Restoran veya yemek ara...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
            ),
          ),
        ),
      ),
    );
  }
  
  SliverToBoxAdapter _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  SliverToBoxAdapter _buildCategoryFilters() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 100, 
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final screenWidth = MediaQuery.of(context).size.width;
            final itemWidth = (screenWidth - 32 - 24) / 3;

            return GestureDetector(
              onTap: () => _navigateToCategory(category.name),
              child: SizedBox(
                width: itemWidth, 
                child: Column(
                  children: [
                    CircleAvatar(radius: 30, child: Icon(category.icon)),
                    const SizedBox(height: 8),
                    Text(category.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAdBanners() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: _buildAdCard(adBanners[0]),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAdCard(adBanners[1]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(String imageUrl) {
    return AspectRatio(
      aspectRatio: 2 / 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }

  SliverList _buildVerticalRestaurantList(List<Restaurant> restaurants) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final restaurant = restaurants[index];
          return GestureDetector(
            onTap: () => _navigateToRestaurant(restaurant),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)) ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                      child: CachedNetworkImage(imageUrl: restaurant.imageUrl, fit: BoxFit.cover, width: 100),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(restaurant.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(restaurant.rating.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 12),
                                const Icon(Icons.delivery_dining, color: Colors.grey, size: 16),
                                const SizedBox(width: 4),
                                Text(restaurant.deliveryTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: restaurants.length,
      ),
    );
  }
}
