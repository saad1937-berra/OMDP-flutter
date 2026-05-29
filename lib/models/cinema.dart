/// Modèle représentant un cinéma
class Cinema {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;
  final double? distance; // En km

  Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
    this.distance,
  });

  /// Données fictives de cinémas pour le fallback
  static List<Cinema> getDemoCinemas() {
    return [
      Cinema(
        id: '1',
        name: 'Cinéma Majestic',
        address: '123 Rue Principale, Casablanca',
        latitude: 33.5731,
        longitude: -7.5898,
        phone: '+212 5 22 23 45 67',
        website: 'www.cinemasmajestic.com',
      ),
      Cinema(
        id: '2',
        name: 'Cinéma Palace',
        address: '456 Avenue Hassan II, Casablanca',
        latitude: 33.5720,
        longitude: -7.5920,
        phone: '+212 5 22 34 56 78',
        website: 'www.cinemapalace.com',
      ),
      Cinema(
        id: '3',
        name: 'Cinéma Star',
        address: '789 Boulevard Sidi Belyout, Casablanca',
        latitude: 33.5740,
        longitude: -7.5880,
        phone: '+212 5 22 45 67 89',
        website: 'www.cinemastar.com',
      ),
      Cinema(
        id: '4',
        name: 'Cinéma Rialto',
        address: '321 Rue Tata, Casablanca',
        latitude: 33.5750,
        longitude: -7.5910,
        phone: '+212 5 22 56 78 90',
      ),
      Cinema(
        id: '5',
        name: 'Cinéma Plaza',
        address: '654 Avenue des FAR, Casablanca',
        latitude: 33.5710,
        longitude: -7.5870,
        phone: '+212 5 22 67 89 01',
        website: 'www.cinemaplaza.com',
      ),
    ];
  }

  @override
  String toString() => 'Cinema($name at $latitude,$longitude)';
}
