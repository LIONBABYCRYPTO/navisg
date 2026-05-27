import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';
import '../widgets/ad_banner.dart';

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
  double _lat = 1.3521;
  double _lng = 103.8198;
  List<_NearbyStop> _nearbyStops = [];
  bool _loading = true;
  String _locationStatus = 'Singapore (default)';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _loading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationStatus = 'GPS off — using default location';
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _locationStatus = 'Location denied — using default location';
        } else {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          );
          _lat = pos.latitude;
          _lng = pos.longitude;
          _locationStatus = 'Your location';
        }
      }
    } catch (_) {
      _locationStatus = 'Using default location (Singapore)';
    }

    _findNearbyStops();
  }

  void _findNearbyStops() {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getLocation,
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding nearby stops...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(
                        _locationStatus.contains('GPS') || _locationStatus.contains('denied')
                            ? Icons.location_off
                            : Icons.my_location,
                        size: 16,
                        color: _locationStatus.contains('Your')
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _locationStatus,
                          style: TextStyle(
                            color: _locationStatus.contains('Your')
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${near.stop.description} ($distStr) — Add from Search',
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
      bottomNavigationBar: const AdBanner(),
    );
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
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
