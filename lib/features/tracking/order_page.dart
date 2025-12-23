import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:intl/intl.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';

class OrderModel {
  final String id;
  final String status;
  final double totalAmount;
  final Timestamp orderDate;
  final List<CartItem> items;
  final String? courierId;
  final GeoPoint? courierLocation;

  OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.orderDate,
    required this.items,
    this.courierId,
    this.courierLocation,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    var itemsData = data['items'] as List<dynamic>? ?? [];
    List<CartItem> orderItems = itemsData.map((itemData) {
      return CartItem(
        name: itemData['name'] ?? 'Bilinmeyen Ürün',
        price: (itemData['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (itemData['quantity'] as num?)?.toInt() ?? 0,
        imageUrl: itemData['imageUrl'] ?? '',
      );
    }).toList();

    return OrderModel(
      id: doc.id,
      status: data['status'] ?? 'Bilinmiyor',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: data['orderDate'] ?? Timestamp.now(),
      items: orderItems,
      courierId: data['courierId'],
      courierLocation: data['courierLocation'] as GeoPoint?,
    );
  }
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
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.red,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Aktif Sipariş', icon: Icon(Icons.delivery_dining)),
            Tab(text: 'Geçmiş Siparişler', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ActiveOrderTab(),
          PastOrdersTab(),
        ],
      ),
    );
  }
}

class ActiveOrderTab extends StatefulWidget {
  const ActiveOrderTab({super.key});

  @override
  State<ActiveOrderTab> createState() => _ActiveOrderTabState();
}

class _ActiveOrderTabState extends State<ActiveOrderTab> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};

  Stream<DocumentSnapshot?> _getActiveOrderStream() {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Yolda')
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
  }

  void _updateMarkerAndCamera(GeoPoint location, OrderModel order) async {
    final GoogleMapController controller = await _controller.future;
    final LatLng courierPosition = LatLng(location.latitude, location.longitude);

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('courier_${order.id}'),
          position: courierPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Kurye', snippet: 'Siparişiniz yolda'),
        ),
      );
    });

    controller.animateCamera(CameraUpdate.newLatLng(courierPosition));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot?>(
      stream: _getActiveOrderStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Aktif sipariş yüklenirken bir hata oluştu.'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Şu anda aktif bir siparişiniz bulunmuyor.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        final order = OrderModel.fromFirestore(snapshot.data!);

        if (order.courierLocation != null) {
          _updateMarkerAndCamera(order.courierLocation!, order);
        }

        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: order.courierLocation != null
                ? LatLng(order.courierLocation!.latitude, order.courierLocation!.longitude)
                : const LatLng(38.6732, 39.2208),
            zoom: 15.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: _markers,
        );
      },
    );
  }
}

class PastOrdersTab extends StatelessWidget {
  const PastOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = auth.FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Geçmiş siparişlerinizi görmek için lütfen giriş yapın.'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Siparişler yüklenirken bir hata oluştu.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('Henüz hiç sipariş vermemişsiniz.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(order.orderDate.toDate());

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  'Sipariş #${order.id.substring(0, 6)}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                trailing: Text(
                  '${order.totalAmount.toStringAsFixed(2)} TL',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                ),
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Durum: ${order.status}', style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 12),
                        const Text('Ürünler:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity} x ${item.name}'),
                              Text('${(item.price * item.quantity).toStringAsFixed(2)} TL'),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
