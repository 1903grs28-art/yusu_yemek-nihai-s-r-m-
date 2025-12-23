// Bu dosyanın tam yolu: lib/models/restaurant_model.dart

class Restaurant {
  final String name;
  final String imageUrl; // Ana resim (liste görünümleri için)
  final String category;
  final double rating;
  final String deliveryTime;
  final List<MenuItem> menu;

  Restaurant({
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.deliveryTime,
    required this.menu,
  });
}

class MenuItem {
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  MenuItem({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });
}
