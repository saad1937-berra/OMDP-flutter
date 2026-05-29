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

  /// Récupère les cinémas proches via Overpass API (OpenStreetMap) - GRATUIT!
  Future<List<Cinema>> getNearbyCinemas({
    required LocationCoordinates userLocation,
    double radiusKm = 10.0,
  }) async {
    try {
      print('🎬 Recherche de cinémas réels via Overpass API...');

      final cinemas = await _fetchCinemasFromOverpass(
        userLocation,
        radiusKm,
      );

      if (cinemas.isNotEmpty) {
        print('✅ ${cinemas.length} cinémas trouvés via Overpass!');
        return cinemas;
      }

      // Fallback si pas de résultats
      print('⚠️ Overpass API ne retourne rien, utilisation données fictives');
      return _getDemoCinemasFallback(userLocation, radiusKm);
    } catch (e) {
      print('❌ Erreur Overpass: $e');
      return _getDemoCinemasFallback(userLocation, radiusKm);
    }
  }

  /// Appel à Overpass API pour trouver les cinémas
  Future<List<Cinema>> _fetchCinemasFromOverpass(
    LocationCoordinates userLocation,
    double radiusKm,
  ) async {
    try {
      // ✅ Requête Overpass simplifiée
      final query = '''[out:json];
(
  node["amenity"="cinema"](around:${(radiusKm * 1000).toInt()},${userLocation.latitude},${userLocation.longitude});
  way["amenity"="cinema"](around:${(radiusKm * 1000).toInt()},${userLocation.latitude},${userLocation.longitude});
  relation["amenity"="cinema"](around:${(radiusKm * 1000).toInt()},${userLocation.latitude},${userLocation.longitude});
);
out center;''';

      final url = 'https://overpass-api.de/api/interpreter';

      print('📡 Appel Overpass API...');
      print('Position: ${userLocation.latitude}, ${userLocation.longitude}');
      print('Rayon: $radiusKm km');

      final response = await http.post(
        Uri.parse(url),
        body: query,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
          'Accept': 'application/json',
          'User-Agent':
              'OMDb-App/1.0 (Flutter)', // ✅ AJOUT: User-Agent important
        },
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Timeout Overpass (20s)'),
      );

      print('📡 Réponse Overpass: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['elements'] == null) {
          print('⚠️ Pas de champ "elements" dans la réponse');
          return [];
        }

        final elements = json['elements'] as List<dynamic>;
        print('📊 ${elements.length} éléments reçus');

        final cinemas = <Cinema>[];
        for (final element in elements) {
          try {
            final cinema = _parseOverpassCinema(element, userLocation);
            if (cinema != null) {
              cinemas.add(cinema);
              print(
                  '✅ ${cinema.name} à ${cinema.distance!.toStringAsFixed(1)}km');
            }
          } catch (e) {
            print('⚠️ Erreur parsing: $e');
            continue;
          }
        }

        print('🎬 Total: ${cinemas.length} cinémas trouvés!');
        return cinemas;
      } else {
        print('❌ Erreur ${response.statusCode}');
        throw Exception('Overpass error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur _fetchCinemasFromOverpass: $e');
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

      // Récupérer les coordonnées
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

  /// Données fictives de secours
  List<Cinema> _getDemoCinemasFallback(
    LocationCoordinates userLocation,
    double radiusKm,
  ) {
    final allCinemas = Cinema.getDemoCinemas();

    final cinemasWithDistance = allCinemas.map((cinema) {
      final distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        cinema.latitude,
        cinema.longitude,
      );

      return Cinema(
        id: cinema.id,
        name: cinema.name,
        address: cinema.address,
        latitude: cinema.latitude,
        longitude: cinema.longitude,
        phone: cinema.phone,
        website: cinema.website,
        distance: distance,
      );
    }).toList();

    final nearCinemas = cinemasWithDistance
        .where((cinema) => cinema.distance! <= radiusKm)
        .toList();

    nearCinemas.sort((a, b) => a.distance!.compareTo(b.distance!));

    return nearCinemas;
  }

  /// Calcule la distance entre deux points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371;
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

  double _toRad(double degree) {
    return degree * math.pi / 180;
  }
}
