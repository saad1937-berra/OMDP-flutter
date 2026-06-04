import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_details.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

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
  late Future<bool> _isFavoriteFuture;
  bool _isFavorite = false;

  MovieReview? _userReview;
  double _userRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _editingReview = false;

  @override
  void initState() {
    super.initState();
    _movieFuture = _apiService.getMovieDetails(widget.imdbId);
    _isFavoriteFuture = _dbService.isFavorite(widget.imdbId);

    _checkIfFavorite();
    _loadUserReview();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _checkIfFavorite() async {
    final isFav = await _dbService.isFavorite(widget.imdbId);
    setState(() {
      _isFavorite = isFav;
    });
  }

  void _loadUserReview() async {
    final review = await _dbService.getReview(widget.imdbId);
    setState(() {
      _userReview = review;
      if (review != null) {
        _userRating = review.personalRating;
        _reviewController.text = review.personalReview;
      }
    });
  }

  void _saveReview(String movieTitle) async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez donner une note')),
      );
      return;
    }

    final review = MovieReview(
      imdbId: widget.imdbId,
      personalRating: _userRating,
      personalReview: _reviewController.text,
      reviewDate: DateTime.now(),
    );

    await _dbService.addOrUpdateReview(review);

    setState(() {
      _userReview = review;
      _editingReview = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avis sauvegardé!')),
    );
  }

  void _deleteReview() async {
    await _dbService.removeReview(widget.imdbId);
    setState(() {
      _userReview = null;
      _userRating = 0;
      _reviewController.clear();
      _editingReview = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avis supprimé')),
    );
  }

  void _toggleFavorite(MovieDetails movie) async {
    if (_isFavorite) {
      await _dbService.removeFavorite(widget.imdbId);
    } else {
      final favorite = FavoriteMovie(
        imdbId: widget.imdbId,
        title: movie.title,
        year: movie.year,
        poster: movie.poster,
        type: movie.type,
        addedDate: DateTime.now(),
      );
      await _dbService.addFavorite(favorite);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _openImdbLink(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  /// Ajouter un film à une collection
  void _addToCollection(MovieDetails movie) async {
    try {
      final collections = await _dbService.getAllCollections();

      if (collections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune collection créée. Créez-en une d\'abord!'),
          ),
        );
        return;
      }

      /// Dialog pour sélectionner une collection
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter à une collection'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];
                final isAlreadyAdded =
                    collection.imdbIds.contains(widget.imdbId);

                return ListTile(
                  title: Text(collection.name),
                  subtitle: Text('${collection.imdbIds.length} film(s)'),
                  trailing: isAlreadyAdded
                      ? const Icon(Icons.check, color: Colors.green)
                      : const Icon(Icons.add),
                  enabled: !isAlreadyAdded,
                  onTap: isAlreadyAdded
                      ? null
                      : () {
                          _addMovieToSelectedCollection(
                            collection,
                            movie,
                          );
                          Navigator.pop(context);
                        },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement')),
      );
    }
  }

  /// Ajouter le film à une collection sélectionnée
  void _addMovieToSelectedCollection(
    MovieCollection collection,
    MovieDetails movie,
  ) async {
    try {
      /// Vérifier si le film est déjà dans la collection
      if (collection.imdbIds.contains(widget.imdbId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce film est déjà dans cette collection'),
          ),
        );
        return;
      }

      /// Ajouter l'ID du film à la collection
      final updatedImdbIds = [...collection.imdbIds, widget.imdbId];

      final updatedCollection = MovieCollection(
        id: collection.id,
        name: collection.name,
        description: collection.description,
        createdDate: collection.createdDate,
        imdbIds: updatedImdbIds,
      );

      /// Ajouter aussi en favori si ce n'est pas déjà le cas
      if (!_isFavorite) {
        final favorite = FavoriteMovie(
          imdbId: widget.imdbId,
          title: movie.title,
          year: movie.year,
          poster: movie.poster,
          type: movie.type,
          addedDate: DateTime.now(),
        );
        await _dbService.addFavorite(favorite);
        setState(() {
          _isFavorite = true;
        });
      }

      /// Mettre à jour la collection
      await _dbService.updateCollection(updatedCollection);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movie.title} ajouté à ${collection.name}!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du film'),
      ),
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
                  Icon(Icons.error_outline,
                      size: 80, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  const Text('Impossible de charger les détails'),
                ],
              ),
            );
          }

          final movie = snapshot.data!;

          return SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Affiche du film
                      if (movie.poster != 'N/A')
                        Image.network(
                          movie.poster,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 300,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Titre et infos de base
                            Text(
                              movie.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              children: [
                                _buildInfoChip(movie.year),
                                _buildInfoChip(movie.type),
                                if (movie.rated != 'N/A')
                                  _buildInfoChip(movie.rated),
                              ],
                            ),

                            const SizedBox(height: 16),

                            /// Note IMDB
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${movie.imdbRating}/10 IMDB',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// Section Avis Personnel
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                border:
                                    Border.all(color: const Color(0xFF00209F)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mon Avis Personnel',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!_editingReview && _userReview != null)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            ...List.generate(5, (index) {
                                              return Icon(
                                                index <
                                                        _userReview!
                                                            .personalRating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.orange,
                                                size: 20,
                                              );
                                            }),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${_userReview!.personalRating.toStringAsFixed(1)}/5',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (_userReview!
                                            .personalReview.isNotEmpty)
                                          Text(
                                            _userReview!.personalReview,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _editingReview = true;
                                                });
                                              },
                                              icon: const Icon(Icons.edit,
                                                  size: 16),
                                              label: const Text('Modifier'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: _deleteReview,
                                              icon: const Icon(Icons.delete,
                                                  size: 16),
                                              label: const Text('Supprimer'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red.shade400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Ma note:'),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            ...List.generate(5, (index) {
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _userRating =
                                                        (index + 1).toDouble();
                                                  });
                                                },
                                                child: Icon(
                                                  index < _userRating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.orange,
                                                  size: 32,
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          controller: _reviewController,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Écris ton avis sur ce film...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () =>
                                              _saveReview(movie.title),
                                          child: const Text('Sauvegarder'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// Synopsis
                            if (movie.plot != 'N/A')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Synopsis',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(movie.plot),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            /// Détails additionnels
                            _buildDetailRow('Réalisateur', movie.director),
                            _buildDetailRow('Acteurs', movie.actors),
                            _buildDetailRow('Genre', movie.genre),
                            _buildDetailRow('Durée', movie.runtime),
                            _buildDetailRow('Langue', movie.language),
                            _buildDetailRow('Pays', movie.country),
                            _buildDetailRow('Récompenses', movie.awards),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Boutons fixes en bas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                          top: BorderSide(
                              color: Colors.grey.shade300, width: 1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
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
                                  backgroundColor: _isFavorite
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openImdbLink(
                                    'https://www.imdb.com/title/${widget.imdbId}/'),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('IMDB'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCollection(movie),
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Ajouter à une collection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00209F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.grey.shade200,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value == 'N/A' || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
