import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';

/// Map screen — shows all bus stops on OpenStreetMap tiles.
/// Users can tap a stop to see its code and name.
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

  // Singapore center
  static const LatLng _sgCenter = LatLng(1.3521, 103.8198);

  @override
  void initState() {
    super.initState();
    // Start with all stops, filter by viewport as user pans
    _filteredStops = widget.allStops;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Filter stops visible in current map bounds for performance
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

  /// Show details when a bus stop marker is tapped
  void _onStopTapped(BusStop stop) {
    setState(() => _selectedStop = stop);
    // Animate to center on selected stop
    _mapController.move(LatLng(stop.latitude, stop.longitude), 13.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
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
        // Selected stop info card
        if (_selectedStop != null)
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
    );
  }
}
