import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/api_service.dart';
import '../widgets/movie_list_item.dart';
import 'movie_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({
    Key? key,
    required this.onThemeToggle,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  late Future<List<Movie>> _moviesFuture;
  List<Movie> _allMovies = [];
  List<Movie> _filteredMovies = [];

  /// Historique de recherche (stocké en mémoire)
  List<String> _searchHistory = [];

  String _selectedSort = 'year-desc';

  /// Filtres avancés
  double _minYear = 1990;
  double _maxYear = 2024;

  late AnimationController _animationController;
  bool _showAdvancedFilters = false;

  @override
  void initState() {
    super.initState();
    _moviesFuture = _apiService.searchMovies(query: 'movie');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Ajoute une recherche à l'historique
  void _addToHistory(String query) {
    if (query.isNotEmpty && query != _searchHistory.firstOrNull) {
      setState(() {
        _searchHistory.removeWhere((item) => item == query);
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }
  }

  void _searchMovies(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredMovies = [];
      });
      return;
    }

    _addToHistory(query);
    _moviesFuture = _apiService.searchMovies(query: query);
    _moviesFuture.then((movies) {
      setState(() {
        _allMovies = movies;
        _applyFiltersAndSort();
      });
    }).catchError((error) {
      setState(() {
        _filteredMovies = [];
      });
    });
  }

  void _applyFiltersAndSort() {
    _filteredMovies = _allMovies;

    /// Filtre par année
    _filteredMovies = _filteredMovies.where((movie) {
      try {
        final year = int.parse(movie.year);
        return year >= _minYear && year <= _maxYear;
      } catch (e) {
        return true;
      }
    }).toList();

    /// Tri selon les critères sélectionnés
    switch (_selectedSort) {
      case 'year-desc':
        _filteredMovies.sort((a, b) => b.year.compareTo(a.year));
        break;
      case 'year-asc':
        _filteredMovies.sort((a, b) => a.year.compareTo(b.year));
        break;
      case 'title':
        _filteredMovies.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher des films'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: widget.onThemeToggle,
              child: Icon(
                widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchMovies,
              decoration: InputDecoration(
                hintText: 'Chercher un film, serie ou acteur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchMovies('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          /// Historique de recherche
          if (_searchHistory.isNotEmpty && _searchController.text.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dernières recherches',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _searchHistory.map((search) {
                      return InputChip(
                        label: Text(search),
                        onPressed: () {
                          _searchController.text = search;
                          _searchMovies(search);
                        },
                        onDeleted: () {
                          setState(() {
                            _searchHistory.remove(search);
                          });
                        },
                        avatar: const Icon(Icons.history, size: 18),
                      );
                    }).toList(),
                  ),
                  const Divider(),
                ],
              ),
            ),

          /// Bouton filtres avancés
          if (_filteredMovies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showAdvancedFilters = !_showAdvancedFilters;
                  });
                },
                icon: Icon(_showAdvancedFilters
                    ? Icons.expand_less
                    : Icons.expand_more),
                label: Text(_showAdvancedFilters
                    ? 'Masquer filtres'
                    : 'Afficher filtres'),
              ),
            ),

          /// Filtres avancés
          if (_showAdvancedFilters && _filteredMovies.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00209F)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Filtre année
                  Text(
                    'Année: ${_minYear.toInt()} - ${_maxYear.toInt()}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  RangeSlider(
                    values: RangeValues(_minYear, _maxYear),
                    min: 1990,
                    max: 2024,
                    onChanged: (values) {
                      setState(() {
                        _minYear = values.start;
                        _maxYear = values.end;
                        _applyFiltersAndSort();
                      });
                    },
                    activeColor: const Color(0xFF00209F),
                  ),
                  const SizedBox(height: 16),

                  /// Tri
                  Text(
                    'Trier par:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedSort,
                    isExpanded: true,
                    onChanged: (value) {
                      setState(() {
                        _selectedSort = value ?? 'year-desc';
                        _applyFiltersAndSort();
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'year-desc',
                        child: Text('Année (récent)'),
                      ),
                      DropdownMenuItem(
                        value: 'year-asc',
                        child: Text('Année (ancien)'),
                      ),
                      DropdownMenuItem(
                        value: 'title',
                        child: Text('Titre (A-Z)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          /// Liste des films
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
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
                        const Text('Erreur lors de la recherche'),
                      ],
                    ),
                  );
                }

                if (_filteredMovies.isEmpty && _searchController.text.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_filter_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text('Commencez a chercher un film...'),
                      ],
                    ),
                  );
                }

                if (_filteredMovies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text('Aucun resultat trouve'),
                      ],
                    ),
                  );
                }

                return FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1)
                      .animate(_animationController),
                  child: ListView.builder(
                    itemCount: _filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = _filteredMovies[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
