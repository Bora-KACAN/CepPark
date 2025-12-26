import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService(); // Servisi çağırdık

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "Aramıza Katıl",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Hemen ücretsiz bir hesap oluştur", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // Ad Soyad
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Ad Soyad",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "E-posta",
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // KAYIT BUTONU
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun")));
                      return;
                    }

                    // Servise gönder
                    String? result = await _authService.register(email, password);

                    if (!mounted) return;

                    if (result == "success") {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt Başarılı! Giriş yapabilirsiniz.")));
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $result")));
                    }
                  },
                  child: const Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}