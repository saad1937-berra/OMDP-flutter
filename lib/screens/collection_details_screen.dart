import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import 'movie_details_screen.dart';

class CollectionDetailsScreen extends StatefulWidget {
  final MovieCollection collection;

  const CollectionDetailsScreen({
    Key? key,
    required this.collection,
  }) : super(key: key);

  @override
  State<CollectionDetailsScreen> createState() =>
      _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService = ApiService();

  late MovieCollection _currentCollection;
  List<FavoriteMovie> _collectionMovies = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  List<Movie> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.collection;
    _loadCollectionMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les films de la collection
  void _loadCollectionMovies() async {
    try {
      final allFavorites = await _dbService.getAllFavorites();

      final moviesInCollection = allFavorites
          .where((fav) => _currentCollection.imdbIds.contains(fav.imdbId))
          .toList();

      setState(() {
        _collectionMovies = moviesInCollection;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement')),
      );
    }
  }

  /// Recherche des films à ajouter
  void _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await _apiService.searchMovies(query: query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de recherche')),
      );
    }
  }

  /// Ajoute un film à la collection
  void _addMovieToCollection(Movie movie) async {
    if (_currentCollection.imdbIds.contains(movie.imdbId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ce film est déjà dans la collection')),
      );
      return;
    }

    try {
      final updatedImdbIds = [..._currentCollection.imdbIds, movie.imdbId];

      final updatedCollection = MovieCollection(
        id: _currentCollection.id,
        name: _currentCollection.name,
        description: _currentCollection.description,
        createdDate: _currentCollection.createdDate,
        imdbIds: updatedImdbIds,
      );

      await _dbService.updateCollection(updatedCollection);

      /// Ajouter aussi comme favori si ce n'est pas déjà le cas
      final isFav = await _dbService.isFavorite(movie.imdbId);
      if (!isFav) {
        final favorite = FavoriteMovie(
          imdbId: movie.imdbId,
          title: movie.title,
          year: movie.year,
          poster: movie.poster,
          type: movie.type,
          addedDate: DateTime.now(),
        );
        await _dbService.addFavorite(favorite);
      }

      setState(() {
        _currentCollection = updatedCollection;
        _searchController.clear();
        _searchResults = [];
      });

      _loadCollectionMovies();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${movie.title} ajouté à la collection!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout')),
      );
    }
  }

  /// Retire un film de la collection
  void _removeMovieFromCollection(String imdbId) async {
    try {
      final updatedImdbIds =
          _currentCollection.imdbIds.where((id) => id != imdbId).toList();

      final updatedCollection = MovieCollection(
        id: _currentCollection.id,
        name: _currentCollection.name,
        description: _currentCollection.description,
        createdDate: _currentCollection.createdDate,
        imdbIds: updatedImdbIds,
      );

      await _dbService.updateCollection(updatedCollection);

      setState(() {
        _currentCollection = updatedCollection;
      });

      _loadCollectionMovies();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Film retiré de la collection')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du retrait')),
      );
    }
  }

  /// Dialog pour ajouter un film
  void _showAddMovieDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un film'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _isSearching = value.isNotEmpty;
                    });
                    _searchMovies(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Chercher un film...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_isSearching && _searchResults.isNotEmpty)
                  Column(
                    children: [
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final movie = _searchResults[index];
                            return ListTile(
                              title: Text(movie.title),
                              subtitle: Text(movie.year),
                              trailing: const Icon(Icons.add),
                              onTap: () {
                                _addMovieToCollection(movie);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCollection.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// Info collection
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: const Color(0xFF00209F).withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentCollection.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (_currentCollection.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_currentCollection.description),
                      ],
                      const SizedBox(height: 12),
                      Chip(
                        label: Text('${_collectionMovies.length} film(s)'),
                        avatar: const Icon(Icons.movie, size: 18),
                      ),
                    ],
                  ),
                ),

                /// Liste des films
                Expanded(
                  child: _collectionMovies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.movie_filter_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text('Aucun film dans cette collection'),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _showAddMovieDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter un film'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12.0),
                          itemCount: _collectionMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _collectionMovies[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              child: ListTile(
                                leading: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MovieDetailsScreen(
                                          imdbId: movie.imdbId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: SizedBox(
                                    width: 40,
                                    child: movie.poster != 'N/A'
                                        ? Image.network(
                                            movie.poster,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade300,
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey.shade300,
                                            child: const Icon(
                                                Icons.image_not_supported),
                                          ),
                                  ),
                                ),
                                title: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MovieDetailsScreen(
                                          imdbId: movie.imdbId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(movie.title),
                                ),
                                subtitle: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MovieDetailsScreen(
                                          imdbId: movie.imdbId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(movie.year),
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Text('Voir les détails'),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MovieDetailsScreen(
                                              imdbId: movie.imdbId,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Text('Retirer',
                                          style: TextStyle(color: Colors.red)),
                                      onTap: () => _removeMovieFromCollection(
                                          movie.imdbId),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMovieDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un film'),
      ),
    );
  }
}
