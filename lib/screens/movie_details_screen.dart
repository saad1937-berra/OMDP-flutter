import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_details.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

/// Écran affichant les détails complets d'un film/série
class MovieDetailsScreen extends StatefulWidget {
  final String imdbId;

  const MovieDetailsScreen({super.key, required this.imdbId});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  late Future<MovieDetails> _movieFuture;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _movieFuture = _apiService.getMovieDetails(widget.imdbId);
    _checkIfFavorite();
  }

  /// Vérifie si le film est dans les favoris
  Future<void> _checkIfFavorite() async {
    final isFav = await _dbService.isFavorite(widget.imdbId);
    setState(() {
      _isFavorite = isFav;
    });
  }

  /// Ajoute/supprime des favoris
  Future<void> _toggleFavorite(MovieDetails movie) async {
    if (_isFavorite) {
      await _dbService.removeFavorite(widget.imdbId);
      _showSnackBar('Supprimé des favoris');
    } else {
      await _dbService.addFavorite(
        FavoriteMovie(
          imdbId: movie.imdbId,
          title: movie.title,
          year: movie.year,
          poster: movie.poster,
          type: movie.type,
          addedDate: DateTime.now(),
        ),
      );
      _showSnackBar('Ajouté aux favoris');
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  /// Ouvre le lien IMDB
  Future<void> _openImdbLink(String url) async {
    final Uri imdbUrl = Uri.parse(url);
    if (await canLaunchUrl(imdbUrl)) {
      await launchUrl(imdbUrl, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Impossible d\'ouvrir le lien');
    }
  }

  /// Affiche un message SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails du film'), elevation: 2.0),
      body: FutureBuilder<MovieDetails>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80.0,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16.0),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final movie = snapshot.data!;
          return Stack(
            children: [
              // Contenu scrollable
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    if (movie.hasPoster)
                      Container(
                        width: double.infinity,
                        height: 300.0,
                        color: Colors.grey[300],
                        child: Image.network(
                          movie.poster,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPosterPlaceholder();
                          },
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 300.0,
                        color: Colors.grey[300],
                        child: _buildPosterPlaceholder(),
                      ),

                    // Contenu
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            movie.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),

                          // Informations principales
                          Row(
                            children: [
                              _buildInfoChip(movie.year),
                              const SizedBox(width: 8.0),
                              _buildInfoChip(movie.type.toUpperCase()),
                              const SizedBox(width: 8.0),
                              _buildInfoChip(movie.rated),
                            ],
                          ),
                          const SizedBox(height: 16.0),

                          // Rating
                          if (movie.imdbRating != 'N/A')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Note: ${movie.imdbRating}/10',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16.0),

                          // Divider
                          const Divider(),
                          const SizedBox(height: 16.0),

                          // Synopsis
                          Text(
                            'Synopsis',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            movie.plot,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16.0),

                          // Détails
                          _buildDetailRow('Réalisateur', movie.director),
                          _buildDetailRow('Acteurs', movie.actors),
                          _buildDetailRow('Genre', movie.genre),
                          _buildDetailRow('Durée', movie.runtime),
                          _buildDetailRow('Langue', movie.language),
                          _buildDetailRow('Pays', movie.country),
                          _buildDetailRow('Sortie', movie.released),
                          _buildDetailRow('Récompenses', movie.awards),
                          _buildDetailRow('Votes IMDB', movie.imdbVotes),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Boutons d'action fixes en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Bouton Favori
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _toggleFavorite(movie),
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                          ),
                          label: Text(_isFavorite ? 'Aimé' : 'Aimer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isFavorite ? Colors.red : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      // Bouton IMDB
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openImdbLink(movie.imdbUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('IMDB'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow.shade700,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Crée un placeholder pour le poster
  Widget _buildPosterPlaceholder() {
    return Center(
      child: Icon(
        Icons.movie_filter_outlined,
        size: 80.0,
        color: Colors.grey[400],
      ),
    );
  }

  /// Crée un chip d'information
  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  /// Crée une ligne de détail
  Widget _buildDetailRow(String label, String value) {
    if (value == 'N/A' || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12.0),
      ],
    );
  }
}
