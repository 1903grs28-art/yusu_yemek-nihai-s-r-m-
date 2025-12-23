import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yusuf_yemek/features/home/home_page.dart';
import 'package:yusuf_yemek/features/auth/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Veri beklenirken veya bağlantı kurulurken yükleniyor ikonu göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Kullanıcı giriş yapmışsa ana sayfayı göster
        if (snapshot.hasData) {
          return const HomePage();
        }
        // Kullanıcı giriş yapmamışsa giriş sayfasını göster
        else {
          return const LoginPage();
        }
      },
    );
  }
}
