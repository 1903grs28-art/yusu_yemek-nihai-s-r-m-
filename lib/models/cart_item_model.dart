class CartItem {
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  // HATA İÇİN EKLENDİ: Firestore'a kaydetmek için toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}
