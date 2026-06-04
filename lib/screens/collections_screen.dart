import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'collection_details_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<MovieCollection>> _collectionsFuture;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _collectionsFuture = _dbService.getAllCollections();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createCollection() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis')),
      );
      return;
    }

    final collection = MovieCollection(
      name: _nameController.text,
      description: _descriptionController.text,
      createdDate: DateTime.now(),
      imdbIds: [],
    );

    _dbService.addCollection(collection).then((_) {
      setState(() {
        _collectionsFuture = _dbService.getAllCollections();
      });

      _nameController.clear();
      _descriptionController.clear();

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection créée!')),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    });
  }

  void _deleteCollection(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              _dbService.removeCollection(id).then((_) {
                setState(() {
                  _collectionsFuture = _dbService.getAllCollections();
                });
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Collection supprimée')),
                );
              });
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la collection',
                hintText: 'Ex: À regarder',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Les films que je veux regarder',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _createCollection,
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Collections'),
      ),
      body: FutureBuilder<List<MovieCollection>>(
        future: _collectionsFuture,
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
                  const Text('Erreur lors du chargement'),
                ],
              ),
            );
          }

          final collections = snapshot.data ?? [];

          if (collections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Aucune collection créée'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Créer une collection'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.folder,
                    color: Color(0xFF00209F),
                  ),
                  title: Text(
                    collection.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (collection.description.isNotEmpty)
                        Text(
                          collection.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${collection.imdbIds.length} film(s)',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionDetailsScreen(
                          collection: collection,
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _collectionsFuture = _dbService.getAllCollections();
                      });
                    });
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Supprimer',
                            style: TextStyle(color: Colors.red)),
                        onTap: () => _deleteCollection(collection.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Créer une collection',
        child: const Icon(Icons.add),
      ),
    );
  }
}
