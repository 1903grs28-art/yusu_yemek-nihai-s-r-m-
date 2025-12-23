import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yusuf_yemek/features/checkout/mobile_payment_page.dart';
import 'package:yusuf_yemek/features/order/order_success_page.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';

enum PaymentMethod { cash, creditCard, mobilePayment }

class PaymentMethodsPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final String deliveryAddress;
  final double totalAmount;

  const PaymentMethodsPage({
    super.key,
    required this.cartItems,
    required this.deliveryAddress,
    required this.totalAmount,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;

  Future<void> _completeOrder() async {
    if (_paymentMethod == PaymentMethod.mobilePayment) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const MobilePaymentPage()),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'items': widget.cartItems.map((item) => item.toMap()).toList(),
          'totalAmount': widget.totalAmount,
          'deliveryAddress': widget.deliveryAddress,
          'paymentMethod': _paymentMethod.name,
          'status': 'Sipariş Alındı',
          'orderDate': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OrderSuccessPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sipariş oluşturulurken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Yöntemi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Lütfen bir ödeme yöntemi seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildPaymentMethodTile(PaymentMethod.cash, 'Kapıda Nakit Ödeme'),
            _buildPaymentMethodTile(PaymentMethod.creditCard, 'Kapıda Kredi Kartı'),
            _buildPaymentMethodTile(PaymentMethod.mobilePayment, 'Mobil Ödeme'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _completeOrder,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Siparişi Tamamla'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, String title) {
    return Card(
      child: RadioListTile<PaymentMethod>(
        title: Text(title),
        value: method,
        groupValue: _paymentMethod,
        onChanged: (value) => setState(() => _paymentMethod = value!),
        activeColor: Colors.red,
      ),
    );
  }
}
