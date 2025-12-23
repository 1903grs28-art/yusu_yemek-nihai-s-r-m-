import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:yusuf_yemek/models/user_model.dart';
import 'package:yusuf_yemek/features/auth/login_page.dart';
import 'package:yusuf_yemek/features/auth/register_page.dart';
import 'package:yusuf_yemek/features/home/home_page.dart';


class SwipeToLogout extends StatefulWidget {
  final VoidCallback onLogoutConfirmed;

  const SwipeToLogout({super.key, required this.onLogoutConfirmed});

  @override
  State<SwipeToLogout> createState() => _SwipeToLogoutState();
}

class _SwipeToLogoutState extends State<SwipeToLogout> {
  final double _startOffset = 4.0;
  late double _dragPosition;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _dragPosition = _startOffset;
  }

  @override
  Widget build(BuildContext context) {
    final double maxDrag = MediaQuery.of(context).size.width - 56;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_isConfirmed) return;
        setState(() {
          _dragPosition += details.delta.dx;
          if (_dragPosition < _startOffset) _dragPosition = _startOffset;
          if (_dragPosition > maxDrag) _dragPosition = maxDrag;
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragPosition >= maxDrag) {
          setState(() => _isConfirmed = true);
          widget.onLogoutConfirmed();
        } else {
          setState(() => _dragPosition = _startOffset);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.zero,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: _isConfirmed ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: const Text(
                '>>> Çıkış için kaydırın >>>',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: _dragPosition,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final User? user;
  final VoidCallback? onLogout;
  final Function(User)? onLoginSuccess;

  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onLoginSuccess,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _userDataFuture = FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return _buildLoggedOutView(context);
    }
    return _buildLoggedInView(context);
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Siparişlerinizi ve bilgilerinizi görmek için giriş yapın veya kayıt olun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Giriş Yap', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _navigateToRegister(context),
                child: const Text('Hesabınız yok mu? Kayıt Olun', style: TextStyle(fontSize: 16, color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('Kullanıcı bilgileri yüklenemedi.')));
        }

        final userData = snapshot.data!.data() ?? {};
        final userName = userData['name'] ?? widget.user?.name ?? 'İsimsiz';
        final photoUrl = userData['photoUrl'];

        return Scaffold(
          backgroundColor: Colors.grey[100],
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildProfileImage(photoUrl),
                      const SizedBox(height: 20),
                      Text(
                        'Hoş geldin, $userName!',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      // DÜZENLEME: E-posta yazısı kaldırıldı.
                      const SizedBox(height: 30),
                      _buildSettingsCard(userData['address'] ?? ''),
                    ],
                  ),
                ),
              ),
              if (widget.onLogout != null)
                SwipeToLogout(onLogoutConfirmed: widget.onLogout!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileImage(String? photoUrl) {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
      child: photoUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
    );
  }

  Widget _buildSettingsCard(String currentAddress) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Colors.red),
            title: const Text('Adresimi Yönet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAddressDialog(context, currentAddress),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.red),
            title: const Text('Şifremi Değiştir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showAddressDialog(BuildContext context, String currentAddress) {
    final addressController = TextEditingController(text: currentAddress);
    bool isLoadingDialog = false;
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adresi Güncelle'),
              content: TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Teslimat Adresi'),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: isLoadingDialog ? null : () async {
                    setDialogState(() => isLoadingDialog = true);
                    final user = auth.FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      try {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                          'address': addressController.text.trim(),
                        }, SetOptions(merge: true));
                        if (mounted) {
                          Navigator.of(context).pop();
                          setState(() { _userDataFuture = FirebaseFirestore.instance.collection('users').doc(widget.user!.uid).get(); });
                        }
                      } catch (e) {
                         if (mounted) Navigator.of(context).pop();
                      }
                    }
                    setDialogState(() => isLoadingDialog = false);
                  },
                  child: isLoadingDialog ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    bool isPasswordVisible = false;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Şifreyi Değiştir'),
              content: TextField(
                controller: newPasswordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Yeni şifrenizi girin",
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('İptal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPasswordController.text.trim().isEmpty) return;
                    try {
                      await auth.FirebaseAuth.instance.currentUser?.updatePassword(newPasswordController.text.trim());
                      if (context.mounted) Navigator.of(context).pop();
                    } on auth.FirebaseAuthException catch (e) {
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Değiştir'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _navigateToLogin(BuildContext context) {
    final onLogin = widget.onLoginSuccess;
    if (onLogin == null) return;
    Navigator.of(context).push<User>(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    ).then((user) {
      if (user != null) {
        onLogin(user);
      }
    });
  }

  void _navigateToRegister(BuildContext context) {
     Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterPage()));
  }
}
