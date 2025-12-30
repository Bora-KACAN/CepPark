import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<String?> startParking({
    required String userId,
    required String parkingLotId,
    required String parkingName,
    required double pricePerHour,
  }) async {
    try {
      
      await _firestore.collection('active_parks').add({
        'userId': userId,
        'parkingLotId': parkingLotId,
        'parkingName': parkingName,
        'entryTime': FieldValue.serverTimestamp(), 
        'pricePerHour': pricePerHour,
        'isActive': true, 
      });
      
      return "success";
    } catch (e) {
      return "Hata oluştu: $e";
    }
  }

  Future<int> getParkingCount(String userId) async {
    
    final snapshot = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: userId)
        .get();

    
    return snapshot.docs.length;
  }
  
  Future<void> updateUserData(String uid, String key, String value) async {
    
    await _firestore.collection('users').doc(uid).set({
      key: value,
    }, SetOptions(merge: true));
  }
  

  
  Future<void> addEmptySpot(double lat, double lng) async {
    await _firestore.collection('open_spots').add({
      'latitude': lat,
      'longitude': lng,
      'reportedAt': FieldValue.serverTimestamp(), 
      'reporterId': FirebaseAuth.instance.currentUser?.uid, 
    });
  }

  
  Stream<QuerySnapshot> getEmptySpots() {
    return _firestore.collection('open_spots').snapshots();
  }

  
  Future<void> removeEmptySpot(String docId) async {
    await _firestore.collection('open_spots').doc(docId).delete();
  }
  
  Future<void> incrementParkingCount(String uid) async {
    
    await _firestore.collection('users').doc(uid).set({
      'parkingCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
  
  Future<void> cleanUpOldSpots() async {
    
    DateTime cutoffTime = DateTime.now().subtract(const Duration(minutes: 30));

    
    var snapshot = await _firestore
        .collection('open_spots')
        .where('reportedAt', isLessThan: cutoffTime)
        .get();

    
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
      print("Eski kayıt silindi: ${doc.id}"); 
    }
  }
  
  Future<void> stopParking(String userId, String parkingLotId) async {
    try {
      
      
      var query = await _firestore
          .collection('active_parks')
          .where('userId', isEqualTo: userId)
          .where('parkingLotId', isEqualTo: parkingLotId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete(); 
      }

      
      await _firestore.collection('parking_lots').doc(parkingLotId).update({
        'currentOccupancy': FieldValue.increment(-1),
      });

      
      await incrementParkingCount(userId);

    } catch (e) {
      print("Çıkış hatası: $e");
    }
  }
  
  
  Future<bool> isUserParked(String userId) async {
    var query = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs.isNotEmpty;
  }
  
  Future<void> occupyStreetSpot(String spotId, double lat, double lng) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    
    await _firestore.collection('open_spots').doc(spotId).delete();

    
    await _firestore.collection('active_parks').add({
      'userId': uid,
      'parkingLotId': 'street_parking', 
      'type': 'street', 
      'latitude': lat, 
      'longitude': lng,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  
  Future<void> leaveStreetSpot() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;

    
    var query = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'street')
        .get();

    for (var doc in query.docs) {
      var data = doc.data();
      
      await addEmptySpot(data['latitude'], data['longitude']);
      
      
      await doc.reference.delete();
    }
    
    
    await incrementParkingCount(uid);
  }

  
  Future<bool> isUserStreetParked() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    var query = await _firestore
        .collection('active_parks')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: 'street')
        .get();
    return query.docs.isNotEmpty;
  }
  
  Future<void> reportAsFull(String docId) async {
    await _firestore.collection('open_spots').doc(docId).delete();
  }
}
