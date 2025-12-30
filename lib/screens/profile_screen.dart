
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; 







class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  bool isLoading = true; 
  
  
  String displayName = "İsim Yok";
  String plaka = "Plaka Yok";
  String telefon = "Telefon Yok";
  String toplamPark = "0 Kez"; 
  String email = "";


  

  @override
  void initState() {
    super.initState();
    _getUserData(); 
  }

  
 Future<void> _getUserData() async {
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    
    setState(() {
      email = user.email ?? "Email Yok"; 
    });

    
    String uid = user.uid;
    var docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    var docSnapshot = await docRef.get();

    if (mounted) {
      if (docSnapshot.exists) {
        
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        setState(() {
          displayName = data['name'] ?? "İsim Yok";
          plaka = data['licensePlate'] ?? "Plaka Yok";
          telefon = data['phoneNumber'] ?? "Telefon Yok";
          
          
          int count = data['parkingCount'] ?? 0;
          toplamPark = "$count Kez";
          isLoading = false;
        });
      } else {
        
        await docRef.set({
          'name': 'Yeni Kullanıcı',
          'licensePlate': '34 TR 00',
          'phoneNumber': '555...',
          'parkingCount': 0,
          'email': user.email, 
        });
        
        setState(() {
          displayName = "Yeni Kullanıcı";
          plaka = "34 TR 00";
          isLoading = false;
        });
      }
    }
  }

  
  String _formatPhoneNumber(String rawNumber) {
    
    String cleanNumber = rawNumber.replaceAll(RegExp(r'\D'), '');

    
    if (cleanNumber.length == 10) {
      return "0 ${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6, 8)} ${cleanNumber.substring(8, 10)}";
    }
    
    else if (cleanNumber.length == 11 && cleanNumber.startsWith('0')) {
      return "${cleanNumber.substring(0, 1)} ${cleanNumber.substring(1, 4)} ${cleanNumber.substring(4, 7)} ${cleanNumber.substring(7, 9)} ${cleanNumber.substring(9, 11)}";
    }
    
    
    return rawNumber;
  }
  
 void _showEditDialog(String title, String currentValue, Function(String) onSave, {bool isNumeric = false}) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$title Düzenle"),
          content: TextField(
            controller: controller,
            
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            
            inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
            decoration: InputDecoration(
              hintText: "Yeni $title giriniz",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: Text("Kaydet", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  


  
  Widget buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap, 
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100], 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueGrey),
            SizedBox(height: 10),
            Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {

    
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Hesabım", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( 
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            SizedBox(height: 15),

            
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                _showEditDialog("Ad Soyad", displayName, (yeniDeger) async {
                  setState(() {
                    displayName = yeniDeger;
                  });
                  
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  await DatabaseService().updateUserData(uid, 'name', yeniDeger);
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName, 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(email, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Üyelik Tipi: Standart", style: TextStyle(color: Colors.grey)),
            
            SizedBox(height: 30),

            
            Row(
              children: [
                Expanded(
                  child: buildInfoCard(
                    title: "Kayıtlı Plaka",
                    value: plaka,
                    icon: Icons.directions_car,
                    onTap: () {
                      _showEditDialog("Plaka", plaka, (yeniDeger) {
                        setState(() {
                          plaka = yeniDeger;
                          // TODO: Firebase güncelleme kodu buraya
                        });
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: buildInfoCard(
                    title: "Toplam Park",
                    value: toplamPark,
                    icon: Icons.history,
                    onTap: null, 
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),

          buildInfoCard(
              title: "Telefon",
              value: _formatPhoneNumber(telefon),
              icon: Icons.phone,
              onTap: () {
                
                _showEditDialog("Telefon", telefon, (yeniDeger) async {
                  setState(() {
                    telefon = yeniDeger;
                    
                  });
                  String uid = FirebaseAuth.instance.currentUser!.uid;
                  await DatabaseService().updateUserData(uid, 'phone', yeniDeger);
                }, isNumeric: true); 
              },
            ),

            SizedBox(height: 40),
            
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout, color: Colors.white),
                label: Text("Çıkış Yap", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async{
                  
                  await FirebaseAuth.instance.signOut();

                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()), 
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}