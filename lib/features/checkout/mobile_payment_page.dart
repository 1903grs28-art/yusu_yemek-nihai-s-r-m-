import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yusuf_yemek/features/order/order_success_page.dart';

class MobilePaymentPage extends StatefulWidget {
  const MobilePaymentPage({super.key});

  @override
  State<MobilePaymentPage> createState() => _MobilePaymentPageState();
}

class _MobilePaymentPageState extends State<MobilePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  void _processPayment() {
    // Butona tekrar tekrar basılmasını engellemek için
    if (_isProcessing) return;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Burada gerçek bir ödeme entegrasyonu (Stripe, Iyzico vb.) yapılır.
      // Bu projede, sadece 2 saniyelik bir gecikme ile başarılı olduğunu varsayıyoruz.
      Future.delayed(const Duration(seconds: 2), () {
        // Önceki tüm sayfaları temizleyerek Sipariş Başarılı sayfasına yönlendir.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OrderSuccessPage()),
              (route) => false,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobil Ödeme'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kart Bilgileri',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Kart Sahibinin Adı Soyadı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Bu alan zorunludur' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Kart Numarası',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v!.isEmpty) return 'Bu alan zorunludur';
                  if (v.length < 16) return 'Geçersiz kart numarası';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Son Kul. Tar. (AA/YY)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (v) {
                        if (v!.isEmpty) return 'Zorunlu';
                        if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(v)) {
                          return 'AA/YY formatı geçersiz';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 3,
                      obscureText: true,
                      validator: (v) {
                        if (v!.isEmpty) return 'Zorunlu';
                        if (v.length < 3) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : const Text(
                    'Ödemeyi Tamamla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
