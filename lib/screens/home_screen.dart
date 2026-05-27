import 'package:flutter/material.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';
import '../services/favorites_service.dart';
import '../widgets/bus_timing_card.dart';
import '../widgets/ad_banner.dart';
import 'search_screen.dart';

/// Home screen — shows saved bus stops with live arrival times
class HomeScreen extends StatefulWidget {
  final LTAService ltaService;
  final FavoritesService favoritesService;
  final List<BusStop> allStops;

  const HomeScreen({
    super.key,
    required this.ltaService,
    required this.favoritesService,
    required this.allStops,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BusStop> _favorites = [];
  bool _loading = true;
  Map<String, dynamic> _arrivalData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await widget.favoritesService.getFavorites();

      if (favorites.isEmpty) {
        setState(() {
          _favorites = [];
          _loading = false;
        });
        return;
      }

      // Fetch arrivals for all favorited stops in parallel
      final results = await Future.wait(
        favorites.map((stop) => widget.ltaService.getBusArrival(stop.stopCode)),
      );

      final arrivalMap = <String, dynamic>{};
      for (int i = 0; i < favorites.length; i++) {
        arrivalMap[favorites[i].stopCode] = results[i];
      }

      setState(() {
        _favorites = favorites;
        _arrivalData = arrivalMap;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Could not load bus data. Check your connection.';
      });
    }
  }

  void _openSearch() async {
    final result = await Navigator.push<BusStop>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          ltaService: widget.ltaService,
          favoritesService: widget.favoritesService,
          allStops: widget.allStops,
        ),
      ),
    );
    if (result != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nāvisg',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Search bus stops',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      // Bottom ad banner
      bottomNavigationBar: const AdBanner(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus,
                  size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 24),
              Text(
                'No Saved Stops Yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap the search icon above to find and save your favorite bus stops.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                label: const Text('Find Bus Stops'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final stop = _favorites[index];
          final services = _arrivalData[stop.stopCode] as List? ?? [];
          return BusTimingCard(
            stop: stop,
            services: services.cast(),
            onRemove: () async {
              await widget.favoritesService.removeFavorite(stop.stopCode);
              _loadData();
            },
            onRefresh: _loadData,
          );
        },
      ),
    );
  }
}

