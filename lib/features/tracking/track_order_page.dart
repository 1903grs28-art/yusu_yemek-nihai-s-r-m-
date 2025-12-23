import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Örnek Sipariş Veri Modeli
class Order {
  final String id;
  final String restaurantName;
  final double totalAmount;
  final DateTime orderDate;
  final String status;

  Order({
    required this.id,
    required this.restaurantName,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
  });
}

class TrackOrderPage extends StatefulWidget {
  const TrackOrderPage({super.key});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişlerim'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif Siparişler'),
            Tab(text: 'Geçmiş Siparişler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActiveOrdersTab(),
          PastOrdersTab(),
        ],
      ),
    );
  }
}

// Aktif Siparişler Sekmesi
class ActiveOrdersTab extends StatelessWidget {
  const ActiveOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Bu kısım gerçek verilerle doldurulacak
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delivery_dining, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Şu anda aktif siparişiniz bulunmuyor.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

// Geçmiş Siparişler Sekmesi
class PastOrdersTab extends StatelessWidget {
  const PastOrdersTab({super.key});

  // Örnek geçmiş sipariş verileri
  static final List<Order> _pastOrders = [
    Order(id: '1', restaurantName: 'Kebap Salonu', totalAmount: 250.0, orderDate: DateTime.now().subtract(const Duration(days: 1)), status: 'Teslim Edildi'),
    Order(id: '2', restaurantName: 'Burger House', totalAmount: 180.0, orderDate: DateTime.now().subtract(const Duration(days: 3)), status: 'İptal Edildi'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_pastOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Daha önce hiç sipariş vermediniz.', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastOrders.length,
      itemBuilder: (context, index) {
        final order = _pastOrders[index];
        final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(order.orderDate);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.restaurantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Tarih: $formattedDate'),
                Text('Tutar: ${order.totalAmount.toStringAsFixed(2)} TL'),
                const SizedBox(height: 8),
                Chip(
                  label: Text(order.status),
                  backgroundColor: order.status == 'Teslim Edildi' ? Colors.green.shade100 : Colors.red.shade100,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
