import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import 'movie_details_screen.dart';

/// Écran affichant les films favoris
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<FavoriteMovie>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Charge la liste des favoris
  void _loadFavorites() {
    setState(() {
      _favoritesFuture = _dbService.getAllFavorites();
    });
  }

  /// Supprime un favori avec confirmation
  Future<void> _deleteFavorite(FavoriteMovie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer du favori'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${movie.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbService.removeFavorite(movie.imdbId);
      _loadFavorites();
      _showSnackBar('${movie.title} supprimé des favoris');
    }
  }

  /// Ouvre le lien IMDB
  Future<void> _openImdbLink(String imdbId) async {
    final Uri imdbUrl = Uri.parse('https://www.imdb.com/title/$imdbId/');
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
      appBar: AppBar(title: const Text('Mes Favoris'), elevation: 2.0),
      body: FutureBuilder<List<FavoriteMovie>>(
        future: _favoritesFuture,
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
                    onPressed: _loadFavorites,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    size: 80.0,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    'Aucun favori',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Ajoutez des films à vos favoris depuis la recherche',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadFavorites();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MovieDetailsScreen(imdbId: favorite.imdbId),
                        ),
                      ).then((_) {
                        // Recharger la liste des favoris au retour
                        _loadFavorites();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: favorite.poster != 'N/A' &&
                                    favorite.poster.isNotEmpty
                                ? Image.network(
                                    favorite.poster,
                                    width: 80.0,
                                    height: 120.0,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderPoster();
                                    },
                                  )
                                : _buildPlaceholderPoster(),
                          ),
                          const SizedBox(width: 12.0),

                          // Informations
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre
                                Text(
                                  favorite.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4.0),

                                // Année et type
                                Row(
                                  children: [
                                    Text(
                                      favorite.year,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 8.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0,
                                        vertical: 2.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.blue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                      child: Text(
                                        favorite.type.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),

                                // Date d'ajout
                                Text(
                                  'Ajouté le ${favorite.addedDate.day}/${favorite.addedDate.month}/${favorite.addedDate.year}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                color: Colors.blue,
                                onPressed: () => _openImdbLink(favorite.imdbId),
                                tooltip: 'Ouvrir sur IMDB',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _deleteFavorite(favorite),
                                tooltip: 'Supprimer',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Crée un placeholder pour le poster
  Widget _buildPlaceholderPoster() {
    return Container(
      width: 80.0,
      height: 120.0,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Icon(
        Icons.movie_filter_outlined,
        size: 40.0,
        color: Colors.grey,
      ),
    );
  }
}
