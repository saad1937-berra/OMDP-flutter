import 'package:geolocator/geolocator.dart';

/// Modèle de coordonnées
class LocationCoordinates {
  final double latitude;
  final double longitude;

  LocationCoordinates({required this.latitude, required this.longitude});

  @override
  String toString() => 'Location($latitude, $longitude)';
}

/// Service de géolocalisation
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Récupère la position actuelle (null si erreur ou refus)
  Future<LocationCoordinates?> getCurrentLocation() async {
    try {
      // Vérifier si le service de localisation est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return null;
    }
  }
}
