import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'movie_details_screen.dart';

/// Écran affichant les films favoris avec statistiques
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        elevation: 0,
      ),
      body: FutureBuilder<List<FavoriteMovie>>(
        /// Récupère tous les films favoris de la base de données
        future: _dbService.getAllFavorites(),
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
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('Erreur lors du chargement'),
                ],
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          /// Affiche un message si aucun favori
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text('Vous n\'avez pas encore de favoris'),
                  const SizedBox(height: 24),
                  Text(
                    'Ajoutez vos films et series preferees!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                /// Section des statistiques personnelles
                _buildStatisticsSection(favorites),
                const SizedBox(height: 24),

                /// Section de la liste des favoris
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Vos favoris (${favorites.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final movie = favorites[index];
                    return _buildFavoriteItem(context, movie);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construit la section des statistiques
  Widget _buildStatisticsSection(List<FavoriteMovie> favorites) {
    /// Calcule les statistiques à partir des favoris
    final totalMovies = favorites.length;
    final byYear = <String, int>{}; // Année en tant que String
    final byType = <String, int>{};

    for (final movie in favorites) {
      /// Compte par année (year est un String)
      byYear[movie.year] = (byYear[movie.year] ?? 0) + 1;

      /// Compte par type
      final type = movie.type.isEmpty ? 'N/A' : movie.type;
      byType[type] = (byType[type] ?? 0) + 1;
    }

    /// Trouve l'année la plus représentée
    final topYear = byYear.isNotEmpty
        ? byYear.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'N/A';

    /// Trouve le type le plus représenté
    final topType = byType.isNotEmpty
        ? byType.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'N/A';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos statistiques',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          /// Grille de statistiques 2x2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              /// Total de favoris
              _buildStatCard(
                title: 'Favoris totaux',
                value: totalMovies.toString(),
                icon: Icons.favorite,
                color: Colors.red,
              ),

              /// Année populaire
              _buildStatCard(
                title: 'Annee top',
                value: topYear,
                icon: Icons.calendar_today,
                color: Colors.blue,
              ),

              /// Type populaire
              _buildStatCard(
                title: 'Type prefere',
                value: topType,
                icon: Icons.movie,
                color: Colors.purple,
              ),

              /// Nombre d'années différentes
              _buildStatCard(
                title: 'Annees differentes',
                value: byYear.length.toString(),
                icon: Icons.diversity_3,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// Affiche les détails par année si disponibles
          if (byYear.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Favoris par annee',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: byYear.entries
                  .toList()
                  .reversed
                  .map((entry) => Chip(
                        label: Text('${entry.key}: ${entry.value}'),
                        avatar: CircleAvatar(
                          child: Text(entry.value.toString()),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Construit une carte de statistique
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Construit un item favori avec menu contextuel
  Widget _buildFavoriteItem(BuildContext context, FavoriteMovie movie) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        /// Affiche le poster du film
        leading: movie.poster != 'N/A'
            ? Image.network(
                movie.poster,
                width: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              )
            : Container(
                width: 50,
                color: Colors.grey.shade300,
                child: const Icon(Icons.movie),
              ),

        /// Titre du film
        title: Text(
          movie.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        /// Année et type du film
        subtitle: Text('${movie.year} - ${movie.type}'),

        /// Menu contextuel
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _removeFavorite(movie.imdbId);
            } else if (value == 'details') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MovieDetailsScreen(imdbId: movie.imdbId),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 8),
                  Text('Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer'),
                ],
              ),
            ),
          ],
        ),

        /// Navigation vers les détails du film au clic
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailsScreen(imdbId: movie.imdbId),
            ),
          );
        },
      ),
    );
  }

  /// Supprime un film des favoris
  void _removeFavorite(String imdbId) {
    _dbService.removeFavorite(imdbId);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retire des favoris'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
