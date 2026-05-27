import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';

/// Nearby screen — shows bus stops near your current GPS location
class NearbyScreen extends StatefulWidget {
  final LTAService ltaService;
  final List<BusStop> allStops;

  const NearbyScreen({
    super.key,
    required this.ltaService,
    required this.allStops,
  });

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  // For MVP, we use default Singapore coordinates
  // In production, use geolocator package for real GPS
  final double _lat = 1.3521; // Default: Singapore city center
  final double _lng = 103.8198;
  List<_NearbyStop> _nearbyStops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _findNearbyStops();
  }

  void _findNearbyStops() {
    setState(() => _loading = true);

    final stops = widget.allStops.map((stop) {
      final distance = _calculateDistance(
        _lat, _lng,
        stop.latitude, stop.longitude,
      );
      return _NearbyStop(stop: stop, distance: distance);
    }).toList();

    stops.sort((a, b) => a.distance.compareTo(b.distance));
    final nearest = stops.take(30).toList();

    setState(() {
      _nearbyStops = nearest;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Using default location (Singapore)',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _nearbyStops.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final near = _nearbyStops[index];
                      final distStr = near.distance < 1000
                          ? '${near.distance.round()}m'
                          : '${(near.distance / 1000).toStringAsFixed(1)}km';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            near.stop.stopCode,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(near.stop.description),
                        subtitle: Row(
                          children: [
                            Icon(Icons.directions_walk,
                                size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('$distStr away'),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to stop detail with bus arrivals
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${near.stop.description} — Add it as a favorite from Search',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        height: 50,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(
          'Ad · Support Navisg',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ),
    );
  }

  /// Haversine distance in meters between two lat/lng points
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(math.pi / 180 * lat1) *
            math.cos(math.pi / 180 * lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return R * c;
  }

  double _toRadians(double deg) => deg * math.pi / 180;
}

class _NearbyStop {
  final BusStop stop;
  final double distance;
  _NearbyStop({required this.stop, required this.distance});
}
