import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cinema.dart';
import 'location_service.dart';
import 'dart:math' as math;

/// Service pour gérer les cinémas proches
class CinemaService {
  static final CinemaService _instance = CinemaService._internal();

  factory CinemaService() {
    return _instance;
  }

  CinemaService._internal();

  /// Récupère les cinémas proches via Overpass API (OpenStreetMap)
  Future<List<Cinema>> getNearbyCinemas({
    required LocationCoordinates userLocation,
    double radiusKm = 10.0,
  }) async {
    try {
      final cinemas = await _fetchCinemasFromOverpass(
        userLocation,
        radiusKm,
      );

      // Retourner les cinémas réels (peuvent être vides si API échoue)
      return cinemas;
    } catch (e) {
      // ✅ Retourner liste vide au lieu du fallback
      return [];
    }
  }

  /// Appel à Overpass API pour trouver les cinémas
  Future<List<Cinema>> _fetchCinemasFromOverpass(
    LocationCoordinates userLocation,
    double radiusKm,
  ) async {
    try {
      final query = '''[out:json];
(
  node["amenity"="cinema"](around:${(radiusKm * 1000).toInt()},${userLocation.latitude},${userLocation.longitude});
  way["amenity"="cinema"](around:${(radiusKm * 1000).toInt()},${userLocation.latitude},${userLocation.longitude});
  relation["amenity"="cinema"](around:${(radiusKm * 1000).toInt()},${userLocation.latitude},${userLocation.longitude});
);
out center;''';

      const url = 'https://overpass-api.de/api/interpreter';

      final response = await http.post(
        Uri.parse(url),
        body: query,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          'Accept': 'application/json',
          'User-Agent': 'OMDb-App/1.0 (Flutter)',
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout Overpass'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['elements'] == null) {
          return [];
        }

        final elements = json['elements'] as List<dynamic>;
        final cinemas = <Cinema>[];

        for (final element in elements) {
          try {
            final cinema = _parseOverpassCinema(element, userLocation);
            if (cinema != null) {
              cinemas.add(cinema);
            }
          } catch (e) {
            continue;
          }
        }

        return cinemas;
      } else {
        throw Exception('Overpass error: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Parse un résultat Overpass en objet Cinema
  Cinema? _parseOverpassCinema(
    Map<String, dynamic> element,
    LocationCoordinates userLocation,
  ) {
    try {
      double lat = 0.0;
      double lng = 0.0;

      if (element.containsKey('lat') && element.containsKey('lon')) {
        lat = (element['lat'] as num).toDouble();
        lng = (element['lon'] as num).toDouble();
      } else if (element.containsKey('center')) {
        final center = element['center'] as Map<String, dynamic>;
        lat = (center['lat'] as num).toDouble();
        lng = (center['lon'] as num).toDouble();
      } else {
        return null;
      }

      final tags = element['tags'] as Map<String, dynamic>?;
      if (tags == null) return null;

      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) return null;

      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        lat,
        lng,
      );

      return Cinema(
        id: element['id'].toString(),
        name: name,
        address: _buildAddress(tags),
        latitude: lat,
        longitude: lng,
        phone: tags['phone'] as String?,
        website:
            tags['website'] as String? ?? tags['contact:website'] as String?,
        distance: distance,
      );
    } catch (e) {
      return null;
    }
  }

  /// Construit une adresse à partir des tags Overpass
  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];

    if (tags['addr:street'] != null) {
      parts.add(tags['addr:street'].toString());
    }
    if (tags['addr:housenumber'] != null) {
      parts.add(tags['addr:housenumber'].toString());
    }
    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city'].toString());
    }

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return tags['addr:full'] as String? ?? 'Adresse inconnue';
  }

  /// Calcule la distance entre deux points (formule Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Rayon de la terre en km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// Convertit les degrés en radians
  double _toRad(double degree) {
    return degree * math.pi / 180;
  }
}
