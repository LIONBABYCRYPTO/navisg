import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/lta_service.dart';
import 'services/favorites_service.dart';
import 'models/bus_stop.dart';
import 'screens/home_screen.dart';
import 'screens/mrt_screen.dart';
import 'screens/carpark_screen.dart';
import 'screens/traffic_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';

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
  bool _darkMode = false;
  bool _chinese = false;

  // Global key to access MapScreen state from bus timing card
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

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

      // Load theme & locale preferences
      final darkMode = prefs.getBool('dark_mode') ?? false;
      final chinese = prefs.getString('navisg_locale') == 'zh';

      _ltaService = LTAService(apiKey);
      _favoritesService = FavoritesService();

      final stops = await _ltaService.getBusStops();
      setState(() {
        _allStops = stops;
        _initializing = false;
        _darkMode = darkMode;
        _chinese = chinese;
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

  /// Called from bus timing card "View Route on Map" to switch tab + show route
  void _showRouteOnMap(String? serviceNo, String? stopCode) {
    setState(() => _currentTab = 1); // Map tab
    // Give the map state a moment to mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapKey.currentState?.setTabIndexFromOutside(serviceNo, stopCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navisg',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE1251B), // Singabus red
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          indicatorColor: const Color(0xFFE1251B).withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE1251B));
            }
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93));
          }),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE1251B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          indicatorColor: const Color(0xFFE1251B).withValues(alpha: 0.2),
        ),
      ),
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
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
      // Tab 0: Saved stops (Home)
      HomeScreen(
        ltaService: _ltaService,
        favoritesService: _favoritesService,
        allStops: _allStops,
        onShowRouteOnMap: _showRouteOnMap,
      ),
      // Tab 1: Unified Map (replaces old Map + Nearby)
      MapScreen(
        key: _mapKey,
        ltaService: _ltaService,
        allStops: _allStops,
      ),
      // Tab 2: Carpark
      CarparkScreen(ltaService: _ltaService, allStops: _allStops),
      // Tab 3: MRT
      MrtScreen(ltaService: _ltaService, allStops: _allStops),
      // Tab 4: Traffic
      TrafficScreen(ltaService: _ltaService, allStops: _allStops),
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.star_border),
            selectedIcon: const Icon(Icons.star),
            label: _chinese ? '收藏' : 'Saved',
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: _chinese ? '地图' : 'Map',
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_parking_outlined),
            selectedIcon: const Icon(Icons.local_parking),
            label: _chinese ? '停车场' : 'Carpark',
          ),
          NavigationDestination(
            icon: const Icon(Icons.train_outlined),
            selectedIcon: const Icon(Icons.train),
            label: _chinese ? '地铁' : 'MRT',
          ),
          NavigationDestination(
            icon: const Icon(Icons.warning_amber_outlined),
            selectedIcon: const Icon(Icons.warning_amber),
            label: _chinese ? '交通' : 'Traffic',
          ),
        ],
      ),
      // Floating settings gear
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'settings',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SettingsScreen(
              allStops: _allStops,
              ltaService: _ltaService,
            ),
          ),
        ).then((_) => _loadPrefsAfterSettings()),
        child: const Icon(Icons.settings),
      ),
    );
  }

  Future<void> _loadPrefsAfterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _chinese = prefs.getString('navisg_locale') == 'zh';
      });
    }
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
