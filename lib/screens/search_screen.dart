import 'package:flutter/material.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';
import '../services/favorites_service.dart';

/// Search screen — find bus stops by code or name
class SearchScreen extends StatefulWidget {
  final LTAService ltaService;
  final FavoritesService favoritesService;
  final List<BusStop> allStops;

  const SearchScreen({
    super.key,
    required this.ltaService,
    required this.favoritesService,
    required this.allStops,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<BusStop> _results = [];
  Set<String> _favoriteCodes = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favs = await widget.favoritesService.getFavorites();
    setState(() => _favoriteCodes = favs.map((s) => s.stopCode).toSet());
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }

    // Search from cached allStops for speed
    final q = query.toUpperCase();
    setState(() {
      _results = widget.allStops.where((stop) {
        return stop.stopCode.contains(q) ||
            stop.description.toUpperCase().contains(q);
      }).take(50).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search by stop code or name...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Type a bus stop code or name',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final stop = _results[index];
                final isFav = _favoriteCodes.contains(stop.stopCode);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      stop.stopCode,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(stop.description),
                  subtitle: Text('Stop ${stop.stopCode}'),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : null,
                    ),
                    onPressed: () async {
                      if (isFav) {
                        await widget.favoritesService
                            .removeFavorite(stop.stopCode);
                      } else {
                        await widget.favoritesService.addFavorite(stop);
                      }
                      _loadFavorites();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFav
                                ? 'Removed ${stop.description}'
                                : 'Saved ${stop.description}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  onTap: () => Navigator.pop(context, stop),
                );
              },
            ),
    );
  }
}
