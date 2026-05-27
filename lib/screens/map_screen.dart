import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_stop.dart';
import '../models/transport_data.dart';
import 'package:navisg/services/lta_service.dart';
import 'package:navisg/services/favorites_service.dart';

/// Unified Map screen — shows all bus stops, tap for live arrivals,
/// GPS location, nearby stops, bus route overlay, and locate-me controls.
class MapScreen extends StatefulWidget {
  final LTAService ltaService;
  final List<BusStop> allStops;

  const MapScreen({
    super.key,
    required this.ltaService,
    required this.allStops,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Timer? _debounce;
  List<BusStop> _filteredStops = [];

  // Selected stop + arrival data
  BusStop? _selectedStop;
  List<BusService> _selectedServices = [];
  bool _loadingArrivals = false;

  // Bus route overlay
  List<BusRouteStop> _routeStops = [];
  String? _routeServiceNo;
  bool _loadingRoute = false;

  // GPS
  double _lat = 1.3521;
  double _lng = 103.8198;
  bool _gpsAvailable = false;
  List<_NearbyStop> _gpsNearbyStops = [];
  bool _showNearby = false;
  bool _loadingGps = false;
  bool _chinese = false;

  static const LatLng _sgCenter = LatLng(1.3521, 103.8198);

  @override
  void initState() {
    super.initState();
    _filteredStops = widget.allStops;
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _chinese = p.getString('navisg_locale') == 'zh');
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void setTabIndexFromOutside(String? serviceNo, String? stopCode) {
    // Called from bus timing card when user taps "View Route on Map"
    if (serviceNo != null) {
      _loadBusRoute(serviceNo);
    }
    if (stopCode != null) {
      final stop = widget.allStops.where((s) => s.stopCode == stopCode).firstOrNull;
      if (stop != null) {
        setState(() {
          _selectedStop = stop;
          _routeStops = [];
          _routeServiceNo = null;
        });
        _mapController.move(LatLng(stop.latitude, stop.longitude), 13.0);
        _loadArrivals(stop.stopCode);
      }
    }
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final bounds = camera.visibleBounds;
      setState(() {
        _filteredStops = widget.allStops.where((stop) {
          return stop.latitude >= bounds.south &&
              stop.latitude <= bounds.north &&
              stop.longitude >= bounds.west &&
              stop.longitude <= bounds.east;
        }).toList();
      });
    });
  }

  void _onStopTapped(BusStop stop) {
    setState(() {
      _selectedStop = stop;
      _selectedServices = [];
      _routeStops = [];
      _routeServiceNo = null;
    });
    _mapController.move(LatLng(stop.latitude, stop.longitude), 13.0);
    _loadArrivals(stop.stopCode);
  }

  Future<void> _loadArrivals(String stopCode) async {
    setState(() => _loadingArrivals = true);
    final services = await widget.ltaService.getBusArrival(stopCode);
    if (mounted) {
      setState(() {
        _selectedServices = services;
        _loadingArrivals = false;
      });
    }
  }

  // --- GPS / Nearby ---

  Future<void> _locateMe() async {
    setState(() => _loadingGps = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_chinese ? '请开启GPS定位' : 'Please enable GPS'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        setState(() => _loadingGps = false);
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPerm = await Geolocator.requestPermission();
        if (newPerm == LocationPermission.denied || newPerm == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_chinese ? '需要位置权限' : 'Location permission needed'),
              ),
            );
          }
          setState(() => _loadingGps = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      _gpsAvailable = true;
      _mapController.move(LatLng(_lat, _lng), 15.0);

      // Find nearby stops
      final all = widget.allStops.map((stop) {
        final dist = _calculateDistance(_lat, _lng, stop.latitude, stop.longitude);
        return _NearbyStop(stop: stop, distance: dist);
      }).toList();
      all.sort((a, b) => a.distance.compareTo(b.distance));
      setState(() {
        _gpsNearbyStops = all.take(15).toList();
        _showNearby = true;
        _loadingGps = false;
      });
    } catch (e) {
      setState(() => _loadingGps = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_chinese ? '定位失败: $e' : 'GPS failed: $e'),
          ),
        );
      }
    }
  }

  // --- Bus Route ---

  Future<void> _loadBusRoute(String serviceNo) async {
    setState(() {
      _loadingRoute = true;
      _routeServiceNo = serviceNo;
      _routeStops = [];
      _selectedStop = null;
      _selectedServices = [];
    });

    final stops = await widget.ltaService.getBusRoute(serviceNo, direction: 1);
    if (stops.isNotEmpty && mounted) {
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (final s in stops) {
        minLat = s.latitude < minLat ? s.latitude : minLat;
        maxLat = s.latitude > maxLat ? s.latitude : maxLat;
        minLng = s.longitude < minLng ? s.longitude : minLng;
        maxLng = s.longitude > maxLng ? s.longitude : maxLng;
      }
      _mapController.move(
        LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
        12.0,
      );
      if (mounted) {
        setState(() {
          _routeStops = stops;
          _loadingRoute = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route $serviceNo ${_chinese ? '暂无数据' : 'not available'}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showRouteSearch() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_chinese ? '查看巴士路线' : 'View Bus Route'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: _chinese ? '巴士编号 (如64)' : 'Service number (e.g. 64)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.directions_bus),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_chinese ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.trim().isNotEmpty) {
                _loadBusRoute(controller.text.trim());
              }
            },
            child: Text(_chinese ? '显示路线' : 'Show Route'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _routeServiceNo != null
              ? '${_chinese ? "巴士" : "Bus"} $_routeServiceNo ${_chinese ? "路线" : "Route"}'
              : (_showNearby ? 'Nearby Map' : 'Map'),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _showRouteSearch,
            tooltip: _chinese ? '查看巴士路线' : 'View bus route',
          ),
          if (_routeServiceNo != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _routeStops = [];
                _routeServiceNo = null;
              }),
              tooltip: _chinese ? '清除路线' : 'Clear route',
            ),
        ],
      ),
      body: Stack(
        children: [
          // --- Map ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sgCenter,
              initialZoom: 11.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onPositionChanged: _onMapMoved,
              onTap: (_, __) {
                setState(() {
                  _selectedStop = null;
                  _selectedServices = [];
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.navisg.navisg',
                maxZoom: 18,
              ),

              // GPS dot
              if (_gpsAvailable)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_lat, _lng),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

              // Bus route polyline
              if (_routeStops.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeStops
                          .map((s) => LatLng(s.latitude, s.longitude))
                          .toList(),
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),

              // Route stop markers
              if (_routeStops.isNotEmpty)
                MarkerLayer(
                  markers: _routeStops.map((s) {
                    return Marker(
                      point: LatLng(s.latitude, s.longitude),
                      width: 22,
                      height: 22,
                      child: GestureDetector(
                        onTap: () {
                          final stop = widget.allStops.where(
                            (bs) => bs.stopCode == s.busStopCode,
                          ).firstOrNull;
                          if (stop != null) _onStopTapped(stop);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${s.stopSequence}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // MRT station markers
              if (_routeStops.isEmpty && _filteredStops.length < 5000)
                MarkerLayer(
                  markers: singaporeMrtStations.map((mrt) {
                    return Marker(
                      point: LatLng(mrt.latitude, mrt.longitude),
                      width: 30,
                      height: 30,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${mrt.name} (${mrt.line} Line)',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _mrtLineColor(mrt.line),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _mrtLineAbbr(mrt.line),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Bus stop markers (when no route)
              if (_routeStops.isEmpty)
                MarkerLayer(
                  markers: _filteredStops.map((stop) {
                    final isSelected = _selectedStop?.stopCode == stop.stopCode;
                    final isNearby = _gpsNearbyStops.any(
                      (n) => n.stop.stopCode == stop.stopCode,
                    );
                    double sz = 28;
                    Color clr = theme.colorScheme.primary;
                    if (isSelected) {
                      sz = 40;
                      clr = Colors.orange;
                    } else if (isNearby && _showNearby) {
                      clr = Colors.green;
                    }
                    return Marker(
                      point: LatLng(stop.latitude, stop.longitude),
                      width: sz,
                      height: sz,
                      child: GestureDetector(
                        onTap: () => _onStopTapped(stop),
                        child: Icon(Icons.directions_bus, color: clr, size: sz - 4),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Route loading indicator
          if (_loadingRoute)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(_chinese ? '加载路线中...' : 'Loading route...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Bottom sheet: selected stop arrivals OR nearby list OR route info ---
          _selectedStop != null && _routeStops.isEmpty
              ? _buildArrivalSheet(theme, isDark)
              : _routeServiceNo != null && _routeStops.isNotEmpty
                  ? _buildRouteInfoBar(theme)
                  : _buildNearbyList(theme, isDark),

          // --- Zoom controls ---
          Positioned(
            right: 8,
            bottom: 120,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom + 1;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom.clamp(5.0, 18.0),
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom - 1;
                    _mapController.move(
                      _mapController.camera.center,
                      zoom.clamp(5.0, 18.0),
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: _loadingGps ? null : _locateMe,
                  child: _loadingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _gpsAvailable ? Icons.my_location : Icons.location_disabled,
                          color: _gpsAvailable ? Colors.blue : Colors.grey,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Arrival bottom sheet ---
  Widget _buildArrivalSheet(ThemeData theme, bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: 310,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedStop!.stopCode,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedStop!.description,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Navigate to this stop on Saved screen
                    IconButton(
                      icon: const Icon(Icons.star_border, size: 20),
                      tooltip: _chinese ? '收藏此站' : 'Save this stop',
                      onPressed: () => _saveStopFromMap(),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _selectedStop = null;
                        _selectedServices = [];
                      }),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Arrivals
              Expanded(
                child: _loadingArrivals
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _selectedServices.isEmpty
                        ? Center(
                            child: Text(
                              _chinese ? '暂无巴士抵达信息' : 'No bus arrivals',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _selectedServices.length,
                            itemBuilder: (context, index) {
                              final svc = _selectedServices[index];
                              return _MapServiceRow(
                                service: svc,
                                chinese: _chinese,
                                onShowRoute: () {
                                  setState(() {
                                    _selectedStop = null;
                                    _selectedServices = [];
                                  });
                                  _loadBusRoute(svc.serviceNo);
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Route info bar ---
  Widget _buildRouteInfoBar(ThemeData theme) {
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _routeServiceNo!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_routeStops.first.roadName} → ${_routeStops.last.roadName}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_routeStops.length} ${_chinese ? "站" : "stops"}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Nearby stops list (when nothing selected and no route) ---
  Widget _buildNearbyList(ThemeData theme, bool isDark) {
    if (!_showNearby || _gpsNearbyStops.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: SizedBox(
        height: 160,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Icon(Icons.near_me, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      _chinese ? '附近车站' : 'Nearby Stops',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showNearby = false),
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _gpsNearbyStops.length,
                  itemBuilder: (context, index) {
                    final near = _gpsNearbyStops[index];
                    final distStr = near.distance < 1000
                        ? '${near.distance.round()}m'
                        : '${(near.distance / 1000).toStringAsFixed(1)}km';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.green.shade100,
                        child: Text(
                          near.stop.stopCode,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        near.stop.description,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        distStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      onTap: () {
                        _mapController.move(
                          LatLng(near.stop.latitude, near.stop.longitude),
                          14.0,
                        );
                        _onStopTapped(near.stop);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveStopFromMap() async {
    if (_selectedStop == null) return;
    final fs = FavoritesService();
    await fs.addFavorite(_selectedStop!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _chinese ? '已收藏 ${_selectedStop!.description}' : 'Saved ${_selectedStop!.description}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- Helpers ---
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin(dLng / 2) * _sin(dLng / 2);
    final c = 2 * _asin(_sqrt(a));
    return R * c;
  }

  double _toRad(double d) => d * 3.141592653589793 / 180;
  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) => x < 0 ? 0 : x > 1 ? 1 : x / (1 + (1 - x) / 2);
  double _asin(double x) {
    if (x < -1) return -1.57079632679;
    if (x > 1) return 1.57079632679;
    return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
  }

  /// Get color for MRT line
  Color _mrtLineColor(String line) {
    switch (line) {
      case 'NS': return const Color(0xFFD42E12); // Red
      case 'EW': return const Color(0xFF009645); // Green
      case 'NE': return const Color(0xFF9900AA); // Purple
      case 'CC': return const Color(0xFFFFA100); // Orange/Yellow
      case 'DT': return const Color(0xFF005EC4); // Blue
      case 'TE': return const Color(0xFF9D5B25); // Brown
      case 'CG': return const Color(0xFF009645); // Green (same as EW)
      case 'LRT': return const Color(0xFF878787); // Grey
      default: return Colors.grey;
    }
  }

  /// Get short abbreviation for MRT line name
  String _mrtLineAbbr(String line) {
    switch (line) {
      case 'NS': return 'NS';
      case 'EW': return 'EW';
      case 'NE': return 'NE';
      case 'CC': return 'CC';
      case 'DT': return 'DT';
      case 'TE': return 'TE';
      case 'CG': return 'CG';
      case 'LRT': return 'L';
      default: return '?';
    }
  }
}

// ---- Map service row widget ----
class _MapServiceRow extends StatelessWidget {
  final BusService service;
  final bool chinese;
  final VoidCallback onShowRoute;

  const _MapServiceRow({
    required this.service,
    required this.chinese,
    required this.onShowRoute,
  });

  @override
  Widget build(BuildContext context) {
    final Color opColor;
    switch (service.operator) {
      case 'SBST':
        opColor = Colors.red;
        break;
      case 'SMRT':
        opColor = Colors.deepPurple;
        break;
      case 'TTS':
        opColor = Colors.orange;
        break;
      case 'GAS':
        opColor = Colors.teal;
        break;
      default:
        opColor = Colors.grey;
    }
    return InkWell(
      onTap: onShowRoute,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: opColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                service.serviceNo,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: opColor),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _ArrTime(label: '1st', info: service.nextBus)),
            Expanded(child: _ArrTime(label: '2nd', info: service.nextBus2)),
            Expanded(child: _ArrTime(label: '3rd', info: service.nextBus3)),
            if (service.nextBus?.isWheelchairAccessible == true ||
                service.nextBus2?.isWheelchairAccessible == true ||
                service.nextBus3?.isWheelchairAccessible == true)
              const Icon(Icons.accessible, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Icon(Icons.route, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ArrTime extends StatelessWidget {
  final String label;
  final BusArrivalInfo? info;
  const _ArrTime({required this.label, required this.info});

  @override
  Widget build(BuildContext context) {
    final mins = info?.minutesUntilArrival;
    String display;
    Color color;
    if (info == null || info!.monitored == 0 || mins == null || mins < 0) {
      display = '-';
      color = Colors.grey;
    } else if (mins == 0) {
      display = 'Arr';
      color = Colors.green;
    } else if (mins <= 3) {
      display = '${mins}m';
      color = Colors.orange.shade700;
    } else {
      display = '${mins}m';
      color = Colors.black87;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        Text(display, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      ],
    );
  }
}

class _NearbyStop {
  final BusStop stop;
  final double distance;
  _NearbyStop({required this.stop, required this.distance});
}
