import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/lta_service.dart';
import 'services/favorites_service.dart';
import 'models/bus_stop.dart';
import 'screens/home_screen.dart';
import 'screens/nearby_screen.dart';
import 'screens/mrt_screen.dart';
import 'screens/carpark_screen.dart';
import 'screens/traffic_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const NavisgApp());
}

class NavisgApp extends StatefulWidget {
  const NavisgApp({super.key});

  @override
  State<NavisgApp> createState() => _NavisgAppState();
}

class _NavisgAppState extends State<NavisgApp> {
  late LTAService _ltaService;
  late FavoritesService _favoritesService;
  List<BusStop> _allStops = [];
  bool _initializing = true;
  String? _initError;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? apiKey = prefs.getString('lta_api_key');

      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _initializing = false;
          _initError = 'api_key_needed';
        });
        return;
      }

      _ltaService = LTAService(apiKey);
      _favoritesService = FavoritesService();

      final stops = await _ltaService.getBusStops();
      setState(() {
        _allStops = stops;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _initError = e.toString();
      });
    }
  }

  void _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lta_api_key', key.trim());
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navisg',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus, size: 64, color: Colors.blue),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading Navisg...'),
            ],
          ),
        ),
      );
    }

    if (_initError == 'api_key_needed') {
      return _ApiKeyInput(onSave: _saveApiKey);
    }

    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to load Navisg'),
                const SizedBox(height: 8),
                Text(_initError!, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _initialize,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final screens = <Widget>[
      HomeScreen(
        ltaService: _ltaService,
        favoritesService: _favoritesService,
        allStops: _allStops,
      ),
      NearbyScreen(
        ltaService: _ltaService,
        allStops: _allStops,
      ),
      CarparkScreen(ltaService: _ltaService),
      MrtScreen(ltaService: _ltaService),
      TrafficScreen(ltaService: _ltaService),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.near_me_outlined),
            selectedIcon: Icon(Icons.near_me),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_parking_outlined),
            selectedIcon: Icon(Icons.local_parking),
            label: 'Carpark',
          ),
          NavigationDestination(
            icon: Icon(Icons.train_outlined),
            selectedIcon: Icon(Icons.train),
            label: 'MRT',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Traffic',
          ),
        ],
      ),
    );
  }
}

/// First-launch screen to enter LTA API key
class _ApiKeyInput extends StatelessWidget {
  final Function(String) onSave;

  const _ApiKeyInput({required this.onSave});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_bus, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Nāvisg',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Real-time SG bus arrivals, MRT, carpark & traffic',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'LTA DataMall API Key',
                  hintText: 'Paste your API key here',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Get Your Free API Key'),
                          content: const Text(
                            '1. Go to datamall.lta.gov.sg\n'
                            '2. Sign up / log in\n'
                            '3. Request for API access\n'
                            '4. Copy your AccountKey\n\n'
                            "It's free and takes 2 minutes.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    if (controller.text.trim().length > 10) {
                      onSave(controller.text.trim());
                    }
                  },
                  child: const Text('Get Started', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your API key stays on your device only.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
