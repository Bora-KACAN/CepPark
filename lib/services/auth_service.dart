import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // KAYIT OLMA
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // GİRİŞ YAPMA
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return "success";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // ÇIKIŞ YAPMA
  Future<void> logout() async {
    await _auth.signOut();
  }
}