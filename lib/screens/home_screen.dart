import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart'; 

import '../services/database_service.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  
  // Haritayı kontrol etmek için
  final MapController _mapController = MapController(); 

  // ---> DEĞİŞKENLER (ARTIK HATASIZ) <---
  LatLng? _initialPosition; // Başlangıç konumu
  bool _isLoading = true;   // Yükleniyor mu?

  @override
  void initState() {
    super.initState();
    _databaseService.cleanUpOldSpots();
    _determinePosition(); // Konumu bulmaya başla
  }

  // --- MEVCUT KONUMU BULMA VE AYARLAMA ---
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Varsayılan Konum (Ankara) - Hata olursa burayı kullanacağız
    LatLng defaultAnkara = const LatLng(39.9355, 32.8236);

    try {
      // 1. GPS Açık mı?
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _initialPosition = defaultAnkara;
            _isLoading = false;
          });
        }
        return;
      }

      // 2. İzin Kontrolü
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // İzin yoksa Ankara'yı aç
          if (mounted) {
            setState(() {
              _initialPosition = defaultAnkara;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Kalıcı red varsa Ankara'yı aç
        if (mounted) {
          setState(() {
            _initialPosition = defaultAnkara;
            _isLoading = false;
          });
        }
        return;
      }

      // 3. Konumu Al
      Position position = await Geolocator.getCurrentPosition();

      // 4. Ekranı Güncelle
      if (mounted) {
        setState(() {
          _initialPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false; // Yükleme bitti, haritayı göster
        });
      }
    } catch (e) {
      // Beklenmedik bir hata olursa yine Ankara'yı aç, uygulama çökmesin
      if (mounted) {
        setState(() {
          _initialPosition = defaultAnkara;
          _isLoading = false;
        });
      }
    }
  }

  // --- HARİTA AÇMA ---
  Future<void> _launchMaps(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      debugPrint("Harita açılamadı.");
    }
  }

  // --- BOŞ YER BİLDİR ---
  Future<void> _reportEmptySpot() async {
    LatLng center = _mapController.camera.center;
    await _databaseService.addEmptySpot(center.latitude, center.longitude);

    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📍 Boş yer bildirildi! Diğer kullanıcılar görüyor."),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- DETAY PENCERESİ ---
  void _showLiveSpotDetails(BuildContext context, String docId, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history, color: Colors.green),
                  ),
                  const SizedBox(width: 15),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Serbest Park Yeri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("Kullanıcı Bildirimi", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchMaps(lat, lng),
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text("Git", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _databaseService.occupyStreetSpot(docId, lat, lng);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Park Edildi! Çıkarken butona basmayı unutma.")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.local_parking, color: Colors.white),
                      label: const Text("Buraya Park Et", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _databaseService.reportAsFull(docId);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Geri bildirim için teşekkürler! İğne kaldırıldı."),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.flag, color: Colors.red),
                  label: const Text("Burası Dolu / Yanlış Bildirim", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CepPark Radar", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
        ],
      ),
      
      floatingActionButton: FutureBuilder<bool>(
        future: _databaseService.isUserStreetParked(),
        builder: (context, snapshot) {
          bool isParked = snapshot.data ?? false;
          if (isParked) {
            return FloatingActionButton.extended(
              onPressed: () async {
                await _databaseService.leaveStreetSpot();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Çıkış yapıldı. Yer tekrar haritada işaretlendi! ♻️")),
                );
              },
              backgroundColor: Colors.redAccent,
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text("Çıkış Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          } else {
            return FloatingActionButton.extended(
              onPressed: () async {
                await _reportEmptySpot();
                setState(() {});
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add_location_alt, color: Colors.white),
              label: const Text("Boş Yer Bildir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // --- GÖVDE (YÜKLENİYORSA BEKLE, BİTTİYSE HARİTA) ---
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Konumun bulunuyor..."),
                ],
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition!, // Artık garanti dolu
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ceppark.app',
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _databaseService.getEmptySpots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    var liveMarkers = snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return Marker(
                        point: LatLng(data['latitude'], data['longitude']),
                        width: 60,
                        height: 60,
                        child: GestureDetector(
                          onTap: () {
                            _showLiveSpotDetails(context, doc.id, data['latitude'], data['longitude']);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.green[800]!, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                            ),
                            child: const Icon(Icons.local_parking, color: Colors.black, size: 30),
                          ),
                        ),
                      );
                    }).toList();
                    return MarkerLayer(markers: liveMarkers);
                  },
                ),
                const Center(
                  child: Icon(Icons.add, color: Colors.black54, size: 30),
                ),
              ],
            ), 
    );
  }
}