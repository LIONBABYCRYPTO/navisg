import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_stop.dart';
import '../models/transport_data.dart';
import '../services/lta_service.dart';

/// Map screen — shows bus stops + bus route polylines on OpenStreetMap tiles.
class MapScreen extends StatefulWidget {
  final LTAService ltaService;
  final List<BusStop> allStops;

  const MapScreen({
    super.key,
    required this.ltaService,
    required this.allStops,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<BusStop> _filteredStops = [];
  BusStop? _selectedStop;
  Timer? _debounce;

  // Bus route overlay
  List<BusRouteStop> _routeStops = [];
  String? _routeServiceNo;
  bool _loadingRoute = false;

  static const LatLng _sgCenter = LatLng(1.3521, 103.8198);

  @override
  void initState() {
    super.initState();
    _filteredStops = widget.allStops;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
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
      _routeStops = [];
      _routeServiceNo = null;
    });
    _mapController.move(LatLng(stop.latitude, stop.longitude), 13.0);
  }

  /// Load bus route overlay for a given service number
  Future<void> _loadBusRoute(String serviceNo) async {
    setState(() {
      _loadingRoute = true;
      _routeServiceNo = serviceNo;
      _routeStops = [];
      _selectedStop = null;
    });

    final stops = await widget.ltaService.getBusRoute(serviceNo, direction: 1);
    if (stops.isNotEmpty && mounted) {
      // Fit map to show the entire route
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (final s in stops) {
        minLat = s.latitude < minLat ? s.latitude : minLat;
        maxLat = s.latitude > maxLat ? s.latitude : maxLat;
        minLng = s.longitude < minLng ? s.longitude : minLng;
        maxLng = s.longitude > maxLng ? s.longitude : maxLng;
      }
      final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
      _mapController.move(center, 12.0);

      setState(() {
        _routeStops = stops;
        _loadingRoute = false;
      });
    } else {
      setState(() => _loadingRoute = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route $serviceNo data not available'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show route search dialog
  void _showRouteSearch() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('View Bus Route'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Service number (e.g. 64)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_bus),
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.trim().isNotEmpty) {
                _loadBusRoute(controller.text.trim());
              }
            },
            child: const Text('Show Route'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _routeServiceNo != null
              ? 'Bus $_routeServiceNo Route'
              : 'Map',
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _showRouteSearch,
            tooltip: 'View bus route',
          ),
          if (_routeServiceNo != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _routeStops = [];
                _routeServiceNo = null;
              }),
              tooltip: 'Clear route',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _sgCenter,
              initialZoom: 11.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onPositionChanged: _onMapMoved,
              onTap: (_, __) {
                if (_selectedStop != null) {
                  setState(() => _selectedStop = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.navisg.navisg',
                maxZoom: 18,
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
                          // Find the full bus stop info
                          final stop = widget.allStops.where(
                            (bs) => bs.stopCode == s.busStopCode,
                          ).firstOrNull;
                          if (stop != null) _onStopTapped(stop);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
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
              // Bus stop markers (only when no route shown)
              if (_routeStops.isEmpty)
                MarkerLayer(
                  markers: _filteredStops.map((stop) {
                    final isSelected =
                        _selectedStop?.stopCode == stop.stopCode;
                    return Marker(
                      point: LatLng(stop.latitude, stop.longitude),
                      width: isSelected ? 40 : 28,
                      height: isSelected ? 40 : 28,
                      child: GestureDetector(
                        onTap: () => _onStopTapped(stop),
                        child: Icon(
                          Icons.directions_bus,
                          color: isSelected
                              ? Colors.orange
                              : theme.colorScheme.primary,
                          size: isSelected ? 36 : 24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          // Route loading indicator
          if (_loadingRoute)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Loading route...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Selected stop info card (only when no route)
          if (_selectedStop != null && _routeStops.isEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_bus,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            _selectedStop!.stopCode,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => _selectedStop = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedStop!.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${_selectedStop!.latitude.toStringAsFixed(4)}, '
                            '${_selectedStop!.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Route info bar
          if (_routeServiceNo != null && _routeStops.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_routeStops.length} stops',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Zoom controls
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
                  heroTag: 'recenter',
                  onPressed: () {
                    _mapController.move(_sgCenter, 11.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
