import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cinema.dart';
import '../services/location_service.dart';
import '../services/cinema_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final CinemaService _cinemaService = CinemaService();

  late MapController _mapController;

  LocationCoordinates? _userLocation;
  List<Cinema> _cinemasProches = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _radiusKm = 10.0;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Attendre que le widget soit construit pour centrer la carte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapReady = true;
        _loadCinemas();
      }
    });
  }

  Future<void> _loadCinemas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Localisation indisponible. Activez le GPS.';
        });
        return;
      }

      final cinemas = await _cinemaService.getNearbyCinemas(
        userLocation: location,
        radiusKm: _radiusKm,
      );

      if (!mounted) return;

      setState(() {
        _userLocation = location;
        _cinemasProches = cinemas;
        _isLoading = false;
        _errorMessage = null;
      });

      // Centrer la carte sur l'utilisateur
      if (_mapReady) {
        try {
          _mapController.move(
            LatLng(location.latitude, location.longitude),
            13,
          );
        } catch (e) {
          debugPrint('Erreur centrage carte: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          child: GestureDetector(
            onTap: _showUserLocationDialog,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: Colors.blue.withAlpha(128), blurRadius: 8),
                ],
              ),
              width: 30,
              height: 30,
              child:
                  const Icon(Icons.my_location, color: Colors.white, size: 16),
            ),
          ),
        ),
      );
    }

    for (final cinema in _cinemasProches) {
      markers.add(
        Marker(
          point: LatLng(cinema.latitude, cinema.longitude),
          child: GestureDetector(
            onTap: () => _showCinemaDetails(cinema),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              width: 40,
              height: 40,
              child: const Icon(Icons.movie, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showUserLocationDialog() {
    if (_userLocation == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Votre position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Latitude: ${_userLocation!.latitude.toStringAsFixed(4)}'),
            Text('Longitude: ${_userLocation!.longitude.toStringAsFixed(4)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCinemaDetails(Cinema cinema) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cinema.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cinema.address),
                      if (cinema.distance != null)
                        Text('${cinema.distance!.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (cinema.phone != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.phone),
                const SizedBox(width: 12),
                Text(cinema.phone!)
              ]),
            ],
            if (cinema.website != null) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.language),
                const SizedBox(width: 12),
                Text(cinema.website!)
              ]),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openInMaps(cinema);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                  ),
                ),
                if (cinema.website != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openWebsite(cinema);
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Site'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMaps(Cinema cinema) async {
    final url =
        Uri.parse('google.navigation:q=${cinema.latitude},${cinema.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Google Maps non installé');
    }
  }

  Future<void> _openWebsite(Cinema cinema) async {
    final url = Uri.parse('https://${cinema.website}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Impossible d\'ouvrir le site');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _setRadius(double newRadius) {
    setState(() => _radiusKm = newRadius);
    _loadCinemas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinémas proches')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 80, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child:
                            Text(_errorMessage!, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                          onPressed: _loadCinemas,
                          child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _userLocation != null
                            ? LatLng(_userLocation!.latitude,
                                _userLocation!.longitude)
                            : const LatLng(33.5731, -7.5898),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.cinema_app',
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),
                    Positioned(
                      bottom: 100,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        onPressed: _loadCinemas,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8)
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.circle_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Slider(
                                    value: _radiusKm,
                                    min: 1,
                                    max: 50,
                                    divisions: 49,
                                    label: '${_radiusKm.toStringAsFixed(0)} km',
                                    onChanged: _setRadius,
                                  ),
                                ),
                                Text('${_radiusKm.toStringAsFixed(0)} km'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('📍 ${_cinemasProches.length} cinémas trouvés',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
