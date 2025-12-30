import 'package:latlong2/latlong.dart'; 

class ParkingLot {
  final String id;
  final String name;
  final LatLng location; 
  final int capacity;
  final int currentOccupancy; 
  final double pricePerHour;      

  

  ParkingLot({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.currentOccupancy,
    required this.pricePerHour,
  });

  
  int get emptySpaces => capacity - currentOccupancy;
}