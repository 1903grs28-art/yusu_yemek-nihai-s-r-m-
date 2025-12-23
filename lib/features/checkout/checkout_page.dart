import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';
import 'package:yusuf_yemek/features/order/order_success_page.dart';

// Adres seçeneği için yeni durum yönetimi
enum AddressOption { saved, newAddress }

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

enum PaymentMethod { cash, creditCard, mobilePayment } // Mobil Ödeme eklendi

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  PaymentMethod? _paymentMethod = PaymentMethod.cash;
  
  // Yeni state'ler
  AddressOption _addressOption = AddressOption.saved;
  bool _saveNewAddress = false;
  String? _savedAddress;
  bool _isLoading = true; // Sayfa yüklenirken animasyon göstermek için

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _nameController.text = data['name'] ?? user.displayName ?? '';
              _phoneController.text = data['phone'] ?? '';
              
              final savedAddr = data['address'];
              if (savedAddr != null && savedAddr.isNotEmpty) {
                _addressController.text = savedAddr;
                _savedAddress = savedAddr;
                _addressOption = AddressOption.saved;
              } else {
                _addressOption = AddressOption.newAddress;
              }
            });
          }
        }
      } catch (e) {
         setState(() => _addressOption = AddressOption.newAddress);
      } finally {
         if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Giriş yapmamış misafir kullanıcı
      if (mounted) {
        setState(() {
           _isLoading = false;
           _addressOption = AddressOption.newAddress;
        });
      }
    }
  }

  double get _totalPrice {
    return widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<void> _completeOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_addressOption == AddressOption.newAddress && _saveNewAddress) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'address': _addressController.text.trim(),
            }, SetOptions(merge: true));
          } catch (e) {
            debugPrint("Adres güncellenirken bir hata oluştu: $e");
          }
        }
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OrderSuccessPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Detayları'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                title: 'Teslimat Bilgileri',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (FirebaseAuth.instance.currentUser != null) ...[
                      TextFormField(
                        controller: _nameController,
                        readOnly: true, // Her zaman düzenlenemez
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad',
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefon Numarası'),
                        keyboardType: TextInputType.phone,
                        validator: (value) => (value == null || value.isEmpty) ? 'Lütfen telefon numaranızı girin' : null,
                      ),
                      const SizedBox(height: 12),
                      if (_savedAddress != null) ...[
                        const Text("Adres Seçimi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        RadioListTile<AddressOption>(
                          title: const Text('Kayıtlı Adresi Kullan'),
                          subtitle: Text(_savedAddress!, maxLines: 2, overflow: TextOverflow.ellipsis),
                          value: AddressOption.saved,
                          groupValue: _addressOption,
                          onChanged: (val) => setState(() {
                            _addressOption = val!;
                            if(val == AddressOption.saved) _addressController.text = _savedAddress!;
                          }),
                        ),
                        RadioListTile<AddressOption>(
                          title: const Text('Yeni Bir Adres Gir'),
                          value: AddressOption.newAddress,
                          groupValue: _addressOption,
                          onChanged: (val) => setState(() {
                            _addressOption = val!;
                            if(val == AddressOption.newAddress) _addressController.clear();
                          }),
                        ),
                      ],
                      if (_addressOption == AddressOption.newAddress)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: _savedAddress != null ? 'Yeni Teslimat Adresi' : 'Teslimat Adresi',
                                  border: const OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                validator: (value) => (value == null || value.isEmpty) ? 'Lütfen adresinizi girin' : null,
                              ),
                              CheckboxListTile(
                                title: const Text("Bu yeni adresi sonraki siparişlerim için kaydet"),
                                value: _saveNewAddress,
                                onChanged: (bool? value) => setState(() => _saveNewAddress = value ?? false),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                    ] else ...[
                      // GİRİŞ YAPMAMIŞ KULLANICI İÇİN ESKİ YAPI
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Lütfen adınızı girin' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefon Numarası'),
                        keyboardType: TextInputType.phone,
                        validator: (value) => (value == null || value.isEmpty) ? 'Lütfen telefon numaranızı girin' : null,
                      ),
                       const SizedBox(height: 12),
                       TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Teslimat Adresi'),
                          maxLines: 3,
                          validator: (value) => (value == null || value.isEmpty) ? 'Lütfen adresinizi girin' : null,
                        ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Ödeme Yöntemi',
                child: Column(
                  children: [
                    RadioListTile<PaymentMethod>(
                      title: const Text('Kapıda Nakit'),
                      value: PaymentMethod.cash,
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value),
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Kapıda Kredi Kartı'),
                      value: PaymentMethod.creditCard,
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value),
                    ),
                    RadioListTile<PaymentMethod>(
                      title: const Text('Mobil Ödeme'),
                      value: PaymentMethod.mobilePayment,
                      groupValue: _paymentMethod,
                      onChanged: (value) => setState(() => _paymentMethod = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Sipariş Özeti',
                child: Column(
                  children: [
                    ...widget.cartItems.map((item) => ListTile(
                          title: Text(item.name),
                          subtitle: Text('${item.quantity} x ${item.price.toStringAsFixed(2)} TL'),
                          trailing: Text('${(item.price * item.quantity).toStringAsFixed(2)} TL', style: const TextStyle(fontWeight: FontWeight.bold)),
                        )),
                    const Divider(),
                    ListTile(
                      title: const Text('Toplam Tutar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      trailing: Text('${_totalPrice.toStringAsFixed(2)} TL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red.shade700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _completeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Siparişi Tamamla', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
