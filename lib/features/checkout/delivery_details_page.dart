import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yusuf_yemek/models/cart_item_model.dart';
import 'package:yusuf_yemek/features/checkout/payment_methods_page.dart';

enum AddressOption { saved, newAddress }

class DeliveryDetailsPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const DeliveryDetailsPage({super.key, required this.cartItems});

  @override
  State<DeliveryDetailsPage> createState() => _DeliveryDetailsPageState();
}

class _DeliveryDetailsPageState extends State<DeliveryDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String? _savedAddress;
  AddressOption? _addressOption;
  bool _isLoading = true;
  bool _saveNewAddress = false;

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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (mounted && doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            final addr = data['address'] as String?;
            if (addr != null && addr.isNotEmpty) {
              _savedAddress = addr;
              _addressOption = AddressOption.saved; // Varsayılan olarak kayıtlı adresi seç
              _addressController.text = addr;
            } else {
              // Kayıtlı adres yoksa, varsayılan olarak yeni adresi seç
              _addressOption = AddressOption.newAddress;
            }
          });
        }
      } catch (e) {
        if (mounted) setState(() => _addressOption = AddressOption.newAddress);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Misafir kullanıcı.
      if (mounted) setState(() => _isLoading = false);
      _addressOption = AddressOption.newAddress;
    }
  }

  void _continueToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final deliveryAddress = _addressController.text.trim();

    if (deliveryAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen bir teslimat adresi belirtin.')),
        );
        return;
    }

    if (_addressOption == AddressOption.newAddress && _saveNewAddress && _auth.currentUser != null) {
      _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'address': deliveryAddress,
      }, SetOptions(merge: true));
    }
    
    final total = widget.cartItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentMethodsPage(
          cartItems: widget.cartItems,
          deliveryAddress: deliveryAddress,
          totalAmount: total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teslimat Detayları')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_auth.currentUser != null) ...[
                      _buildReadOnlyField('Ad Soyad', _nameController.text),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Telefon Numarası', border: OutlineInputBorder()),
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Telefon numarası gerekli' : null,
                      ),
                      const SizedBox(height: 24),
                      const Text('Adres Seçimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // DÜZELTME: Bu bölüm her zaman gösterilecek şekilde yeniden düzenlendi.
                      RadioListTile<AddressOption>(
                        title: const Text('Kayıtlı Adresi Kullan'),
                        subtitle: Text(_savedAddress ?? 'Kayıtlı adres bulunmuyor'),
                        value: AddressOption.saved,
                        groupValue: _addressOption,
                        onChanged: _savedAddress == null ? null : (v) => setState(() {
                          _addressOption = v!;
                          _addressController.text = _savedAddress!;
                        }),
                        activeColor: Colors.red,
                      ),
                      RadioListTile<AddressOption>(
                        title: const Text('Yeni Bir Adres Gir'),
                        value: AddressOption.newAddress,
                        groupValue: _addressOption,
                        onChanged: (v) => setState(() {
                          _addressOption = v!;
                          if (_addressOption == AddressOption.newAddress) {
                            _addressController.clear();
                          }
                        }),
                        activeColor: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      
                      if (_addressOption == AddressOption.newAddress)
                        _buildNewAddressForm(),

                    ] else ...[
                      _buildGuestForm(),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _continueToPayment,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Ödeme Yöntemine Devam Et'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      child: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildNewAddressForm() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(labelText: _savedAddress != null ? 'Yeni Teslimat Adresi' : 'Teslimat Adresi', border: const OutlineInputBorder()),
          maxLines: 3,
          validator: (v) => v!.isEmpty ? 'Adres alanı boş bırakılamaz' : null,
        ),
        if (_auth.currentUser != null)
          CheckboxListTile(
            title: const Text('Bu yeni adresi kaydet'),
            value: _saveNewAddress,
            onChanged: (val) => setState(() => _saveNewAddress = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildGuestForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder()),
          validator: (v) => v!.isEmpty ? 'İsim gerekli' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Telefon Numarası', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Telefon numarası gerekli' : null,
        ),
        const SizedBox(height: 16),
        _buildNewAddressForm(), 
      ],
    );
  }
}
