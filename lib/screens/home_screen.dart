import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';
import '../services/favorites_service.dart';
import '../services/favorite_routes_service.dart';
import '../services/l10n.dart';
import '../widgets/bus_timing_card.dart';
import '../widgets/ad_banner.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Home screen — shows saved bus stops with live arrival times.
/// Features: auto-refresh, direction filter, drag-to-reorder, search filter.
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
  DateTime? _lastUpdated;
  String _searchFilter = '';
  bool _chinese = false;

  // Auto-refresh
  Timer? _autoRefreshTimer;
  bool _autoRefresh = true;
  static const _refreshInterval = Duration(seconds: 30);

  // Reorder
  bool _isReordering = false;
  // Favorite routes
  List<FavoriteRoute> _favoriteRoutes = [];
  bool _showFavoriteRoutes = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadData();
    _loadFavoriteRoutes();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _chinese = prefs.getString('navisg_locale') == 'zh';
      _autoRefresh = prefs.getBool('navisg_auto_refresh') ?? true;
    });
    if (_autoRefresh) _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted && _favorites.isNotEmpty) _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      final results = await Future.wait(
        _favorites.map((stop) => widget.ltaService.getBusArrival(stop.stopCode)),
      );

      final arrivalMap = <String, dynamic>{};
      for (int i = 0; i < _favorites.length; i++) {
        arrivalMap[_favorites[i].stopCode] = results[i];
      }

      if (mounted) {
        setState(() {
          _arrivalData = arrivalMap;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadFavoriteRoutes() async {
    final fav = FavoriteRoutesService();
    final routes = await fav.getRoutes();
    if (mounted) {
      setState(() => _favoriteRoutes = routes);
    }
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
        _lastUpdated = DateTime.now();
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

  List<BusStop> get _filteredFavorites {
    var list = _favorites;
    if (_searchFilter.isNotEmpty) {
      final q = _searchFilter.toLowerCase();
      list = list.where((s) =>
          s.stopCode.contains(q) || s.description.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return _chinese ? '刚刚' : 'just now';
    if (diff.inMinutes == 1) return _chinese ? '1分钟前' : '1 min ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}${_chinese ? '分钟前' : ' min ago'}';
    return '${diff.inHours}${_chinese ? '小时前' : 'h ago'}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFavorites;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _chinese ? '畅行狮城' : 'Nāvisg',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: _chinese ? '搜索巴士站' : 'Search bus stops',
          ),
          IconButton(
            icon: _autoRefresh
                ? const Icon(Icons.timer)
                : Icon(Icons.timer_off, color: Colors.grey.shade500),
            onPressed: () {
              setState(() {
                _autoRefresh = !_autoRefresh;
              });
              SharedPreferences.getInstance().then(
                (p) => p.setBool('navisg_auto_refresh', _autoRefresh),
              );
              if (_autoRefresh) {
                _startAutoRefresh();
              } else {
                _autoRefreshTimer?.cancel();
              }
            },
            tooltip: _chinese ? '自动刷新' : 'Auto-refresh',
          ),
          IconButton(
            icon: _isReordering ? const Icon(Icons.check) : const Icon(Icons.sort),
            onPressed: () => setState(() => _isReordering = !_isReordering),
            tooltip: _isReordering
                ? (_chinese ? '完成排序' : 'Done reordering')
                : (_chinese ? '排序' : 'Reorder'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: _chinese ? '刷新' : 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  allStops: widget.allStops,
                  ltaService: widget.ltaService,
                ),
              ),
            ).then((_) => _loadPrefs()),
            tooltip: _chinese ? '设置' : 'Settings',
          ),
        ],
      ),
      body: _buildBody(filtered),
      bottomNavigationBar: _favorites.isNotEmpty ? const AdBanner() : null,
    );
  }

  Widget _buildBody(List<BusStop> filtered) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              _chinese ? '正在加载...' : 'Loading Navisg...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
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
              label: Text(_chinese ? '重试' : 'Retry'),
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
                L10n.tr(AppStrings.noSavedStops, chinese: _chinese),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                L10n.tr(AppStrings.findStopsHint, chinese: _chinese),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openSearch,
                icon: const Icon(Icons.search),
                label: Text(L10n.tr(AppStrings.findStops, chinese: _chinese)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Inline filter field
          if (_favorites.length > 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: L10n.tr(AppStrings.filterStops, chinese: _chinese),
                  prefixIcon: const Icon(Icons.filter_list, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (v) => setState(() => _searchFilter = v),
              ),
            ),
          // Auto-refresh badge
          if (_autoRefresh && _lastUpdated != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 12, color: Colors.green.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${L10n.tr(AppStrings.updated, chinese: _chinese)} ${_timeAgo(_lastUpdated!)}',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade600),
                  ),
                  const Spacer(),
                  Text(
                    '${_chinese ? '自动刷新中' : 'Auto-refreshing'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          // Saved routes section
          if (_favoriteRoutes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                onTap: () => setState(() => _showFavoriteRoutes = !_showFavoriteRoutes),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.route, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        _chinese ? '已保存路线' : 'Saved Routes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        ' (${_favoriteRoutes.length})',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const Spacer(),
                      Icon(
                        _showFavoriteRoutes
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showFavoriteRoutes && _favoriteRoutes.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _favoriteRoutes.length,
                itemBuilder: (context, index) {
                  final route = _favoriteRoutes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: const Icon(Icons.directions_bus, size: 16),
                      label: Text('${route.serviceNo} @ ${route.stopCode}'),
                      onDeleted: () async {
                        final fav = FavoriteRoutesService();
                        await fav.removeRoute(route.serviceNo, route.stopCode);
                        _loadFavoriteRoutes();
                      },
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: _isReordering
                ? _buildReorderableList(filtered)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return _LastUpdatedBadge(
                          lastUpdated: _lastUpdated,
                          chinese: _chinese,
                        );
                      }
                      final stop = filtered[index];
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
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(List<BusStop> filtered) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      itemCount: filtered.length,
      onReorder: (oldIndex, newIndex) async {
        await widget.favoritesService.moveFavorite(oldIndex, newIndex);
        _loadData();
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final double elevation = Tween<double>(begin: 0, end: 6)
                .animate(animation)
                .value;
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final stop = filtered[index];
        final services = _arrivalData[stop.stopCode] as List? ?? [];
        return BusTimingCard(
          key: ValueKey(stop.stopCode),
          stop: stop,
          services: services.cast(),
          onRemove: () async {
            await widget.favoritesService.removeFavorite(stop.stopCode);
            _loadData();
          },
          onRefresh: _loadData,
          isDragging: false,
        );
      },
    );
  }
}

class _LastUpdatedBadge extends StatelessWidget {
  final DateTime? lastUpdated;
  final bool chinese;

  const _LastUpdatedBadge({this.lastUpdated, this.chinese = false});

  @override
  Widget build(BuildContext context) {
    if (lastUpdated == null) return const SizedBox.shrink();
    final ago = _timeAgo(lastUpdated!);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              '${chinese ? '更新于' : 'Updated'} $ago',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return chinese ? '刚刚' : 'just now';
    if (diff.inMinutes == 1) return chinese ? '1分钟前' : '1 min ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}${chinese ? '分钟前' : ' min ago'}';
    return '${diff.inHours}${chinese ? '小时前' : 'h ago'}';
  }
}
