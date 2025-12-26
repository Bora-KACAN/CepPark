import 'package:latlong2/latlong.dart'; // Konum için lazım

class ParkingLot {
  final String id;
  final String name;
  final LatLng location; // Haritadaki yeri
  final int capacity;
  final int currentOccupancy; // Doluluk
  final double pricePerHour;

  ParkingLot({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.currentOccupancy,
    required this.pricePerHour,
  });

  // Boş yer sayısını hesaplayan küçük bir özellik
  int get emptySpaces => capacity - currentOccupancy;
}