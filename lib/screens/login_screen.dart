import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Servis
import 'register_screen.dart'; // Kayıt Ekranı
import 'home_screen.dart'; // Ana Sayfa

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Kutucukları okumak için
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Servisimizi çağırıyoruz
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_parking, size: 100, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "CepPark'a Hoş Geldin",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text("Devam etmek için giriş yapın", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),

              // E-posta
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

              // GİRİŞ BUTONU
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    String email = _emailController.text.trim();
                    String password = _passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bilgileri giriniz")));
                      return;
                    }

                    // Servise sor: Giriş yapabilir mi?
                    String? result = await _authService.login(email, password);

                    if (result == "success") {
                      // Başarılıysa Ana Sayfaya (Home) git
                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    } else {
                      // Hata varsa göster
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $result")));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Giriş Yap", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              // Kayıt Ol Linki
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hesabın yok mu?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text("Kayıt Ol"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}