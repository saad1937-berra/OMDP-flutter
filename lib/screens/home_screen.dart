import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_list_item.dart';
import 'movie_details_screen.dart';

/// Écran de recherche de films/séries
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  String _lastQuery = '';
  bool _hasMoreResults = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Appelé lorsqu'on scroll vers le bas pour charger plus de résultats
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreResults && !_isLoading) {
        _loadMoreMovies();
      }
    }
  }

  /// Recherche des films
  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _movies = [];
        _errorMessage = null;
        _currentPage = 1;
        _lastQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _movies = [];
      _lastQuery = query;
    });

    try {
      final movies = await _apiService.searchMovies(query: query, page: 1);

      setState(() {
        _movies = movies;
        _isLoading = false;
        _hasMoreResults = movies.length >= 10;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString()}';
        _movies = [];
      });
    }
  }

  /// Charge la page suivante de résultats
  Future<void> _loadMoreMovies() async {
    if (_lastQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newMovies = await _apiService.searchMovies(
        query: _lastQuery,
        page: _currentPage + 1,
      );

      setState(() {
        _movies.addAll(newMovies);
        _currentPage++;
        _isLoading = false;
        _hasMoreResults = newMovies.length >= 10;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher des films'), elevation: 2.0),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Entrez un titre de film...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _movies = [];
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
              onSubmitted: (value) {
                _searchMovies(value);
              },
            ),
          ),

          // Bouton de recherche
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        _searchMovies(_searchController.text);
                      },
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Rechercher'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

          // Contenu principal
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Construit le contenu principal
  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget(_errorMessage!);
    }

    if (_movies.isEmpty && _lastQuery.isNotEmpty && !_isLoading) {
      return _buildEmptyWidget();
    }

    if (_movies.isEmpty && _lastQuery.isEmpty) {
      return _buildWelcomeWidget();
    }

    return Stack(
      children: [
        // Liste des films
        ListView.builder(
          controller: _scrollController,
          itemCount: _movies.length + (_hasMoreResults && _isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _movies.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final movie = _movies[index];
            return MovieListItem(
              movie: movie,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MovieDetailsScreen(imdbId: movie.imdbId),
                  ),
                );
              },
            );
          },
        ),

        // Indicateur de chargement au centre (pour première recherche)
        if (_isLoading && _movies.isEmpty)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  /// Widget de bienvenue
  Widget _buildWelcomeWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            size: 80.0,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 24.0),
          Text(
            'Bienvenue sur OMDb Movie App',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Text(
            'Entrez un titre de film pour commencer',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget vide (pas de résultats)
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80.0, color: Colors.grey.shade400),
          const SizedBox(height: 24.0),
          Text(
            'Aucun résultat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12.0),
          Text(
            'Aucun film trouvé pour "$_lastQuery"',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Widget d'erreur
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80.0, color: Colors.red.shade400),
          const SizedBox(height: 24.0),
          Text(
            'Une erreur est survenue',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
