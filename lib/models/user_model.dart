import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String name;
  final String? email;
  final String? address;
  final String? phone;
  final String? photoUrl;

  User({
    required this.uid,
    required this.name,
    this.email,
    this.address,
    this.phone,
    this.photoUrl,
  });

  // Firestore'dan gelen veriyi User modeline dönüştüren factory constructor
  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return User(
      uid: doc.id,
      name: data['name'] ?? 'İsimsiz Kullanıcı',
      email: data['email'] as String?,
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }
}
