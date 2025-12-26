import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  // Veritabanı aracımızı çağırıyoruz
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PARK İŞLEMİNİ BAŞLAT
  Future<String?> startParking({
    required String userId,
    required String parkingLotId,
    required String parkingName,
    required double pricePerHour,
  }) async {
    try {
      // 'active_parks' adında bir çekmece (koleksiyon) açıp içine fişi koyuyoruz
      await _firestore.collection('active_parks').add({
        'userId': userId,
        'parkingLotId': parkingLotId,
        'parkingName': parkingName,
        'entryTime': FieldValue.serverTimestamp(), // Giriş saati (Sunucudan alınır)
        'pricePerHour': pricePerHour,
        'isActive': true, // Park şu an devam ediyor mu? Evet.
      });
      
      return "success";
    } catch (e) {
      return "Hata oluştu: $e";
    }
  }
// PARK SAYISINI GETİR (Profil İçin)
  Future<int> getParkingCount(String userId) async {
    // Veritabanında ismi 'userId' olan ve değeri bizim ID'miz olanları bul
    final snapshot = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: userId)
        .get();

    // Kaç tane bulduysan sayısını döndür
    return snapshot.docs.length;
  }
  // Kullanıcı verisini güncellemek için genel fonksiyon
  Future<void> updateUserData(String uid, String key, String value) async {
    // .update yerine .set kullanıyoruz ve merge: true diyoruz.
    // Bu sayede belge yoksa oluşturur, varsa sadece ilgili alanı günceller.
    await _firestore.collection('users').doc(uid).set({
      key: value,
    }, SetOptions(merge: true));
  }
  // --- RADARBOT / WAZE MANTIĞI: BOŞ PARK YERİ PAYLAŞIMI ---

  // 1. Boş bir park yeri bildir (Konum ve Zaman ekler)
  Future<void> addEmptySpot(double lat, double lng) async {
    await _firestore.collection('open_spots').add({
      'latitude': lat,
      'longitude': lng,
      'reportedAt': FieldValue.serverTimestamp(), // Ne zaman eklendi?
      'reporterId': FirebaseAuth.instance.currentUser?.uid, // Kim ekledi?
    });
  }

  // 2. Haritadaki boş yerleri CANLI DİNLE (Stream)
  // Sadece son 30 dakikada eklenenleri çekmek için filtreleme de yapılabilir ama şimdilik hepsini çekelim, ekran tarafında süzeriz.
  Stream<QuerySnapshot> getEmptySpots() {
    return _firestore.collection('open_spots').snapshots();
  }

  // 3. Yer dolduysa veya ben park ettiysem o iğneyi SİL
  Future<void> removeEmptySpot(String docId) async {
    await _firestore.collection('open_spots').doc(docId).delete();
  }
  // Kullanıcının toplam park sayısını 1 artırır
  Future<void> incrementParkingCount(String uid) async {
    // 'users' koleksiyonundaki belgeyi bul ve 'parkingCount' alanını 1 artır.
    // Eğer böyle bir alan yoksa oluşturur (SetOptions merge sayesinde).
    await _firestore.collection('users').doc(uid).set({
      'parkingCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
  // --- OTOMATİK TEMİZLİK SİSTEMİ ---
  // 30 dakikadan eski olan "Boş Yer" bildirimlerini siler
  Future<void> cleanUpOldSpots() async {
    // 1. Zaman sınırını belirle (Şu an - 30 dakika)
    DateTime cutoffTime = DateTime.now().subtract(const Duration(minutes: 30));

    // 2. Bu sınırdan eski olanları bul
    // Not: 'reportedAt' alanı Timestamp olduğu için karşılaştırma yapabiliriz
    var snapshot = await _firestore
        .collection('open_spots')
        .where('reportedAt', isLessThan: cutoffTime)
        .get();

    // 3. Hepsini sil
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      print("Eski kayıt silindi: ${doc.id}"); // Konsola bilgi verelim
    }
  }
  // --- SABİT OTOPARKTAN ÇIKIŞ YAP (Basit Versiyon) ---
  Future<void> stopParking(String userId, String parkingLotId) async {
    try {
      // 1. 'active_parks' tablosundan kaydı sil (Artık park halinde değil)
      // Önce kullanıcının aktif kaydını bulmamız lazım
      var query = await _firestore
          .collection('active_parks')
          .where('userId', isEqualTo: userId)
          .where('parkingLotId', isEqualTo: parkingLotId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete(); // Kaydı sil
      }

      // 2. Otoparkın doluluk sayısını 1 azalt
      await _firestore.collection('parking_lots').doc(parkingLotId).update({
        'currentOccupancy': FieldValue.increment(-1),
      });

      // 3. Kullanıcının "Toplam Park" sayısını 1 artır (Profil için)
      await incrementParkingCount(userId);

    } catch (e) {
      print("Çıkış hatası: $e");
    }
  }
  
  // Kullanıcının şu an park edip etmediğini kontrol et
  Future<bool> isUserParked(String userId) async {
    var query = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs.isNotEmpty;
  }
  // --- YENİ DÖNGÜ: SOKAK PARKI SİSTEMİ ---

  // 1. Sokaktaki yeri KAP (Park Et)
  // Bu fonksiyon: Yeşil iğneyi siler VE kullanıcıyı 'active_parks' tablosuna 'street' olarak kaydeder.
  Future<void> occupyStreetSpot(String spotId, double lat, double lng) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // A. Yeşil iğneyi haritadan sil (Başkası görmesin, çünkü biz kaptık)
    await _firestore.collection('open_spots').doc(spotId).delete();

    // B. Kullanıcıyı "Park Halinde" olarak işaretle (Konumuyla beraber)
    await _firestore.collection('active_parks').add({
      'userId': uid,
      'parkingLotId': 'street_parking', // Sabit ID değil, sokak parkı olduğunu belirtiyoruz
      'type': 'street', // Türü sokak
      'latitude': lat, // Çıkarken bu konuma iğne atacağız
      'longitude': lng,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // 2. Sokaktaki yerden ÇIK (Yeri Geri Bırak)
  // Bu fonksiyon: Kullanıcıyı boşa düşürür VE çıktığı yere tekrar YEŞİL İĞNE atar.
  Future<void> leaveStreetSpot() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    // A. Kullanıcının park kaydını bul
    var query = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'street')
        .get();

    for (var doc in query.docs) {
      var data = doc.data();
      // B. Çıktığı konuma YENİ BİR YEŞİL İĞNE at (Otomatik Boş Yer Bildirimi)
      await addEmptySpot(data['latitude'], data['longitude']);
      
      // C. Park kaydını sil
      await doc.reference.delete();
    }
    
    // D. Sayacı artır
    await incrementParkingCount(uid);
  }

  // 3. Kullanıcının şu an SOKAKTA park edip etmediğini kontrol et
  Future<bool> isUserStreetParked() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    var query = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'street')
        .get();
    return query.docs.isNotEmpty;
  }
  // --- YENİ: HATALI VEYA DOLU BİLDİRİMİ ---
  // Kullanıcı "Burası dolu!" derse iğneyi siliyoruz
  Future<void> reportAsFull(String docId) async {
    await _firestore.collection('open_spots').doc(docId).delete();
  }
}
