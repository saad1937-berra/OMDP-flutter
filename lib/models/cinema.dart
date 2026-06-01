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

  @override
  String toString() => 'Cinema($name at $latitude,$longitude)';
}
