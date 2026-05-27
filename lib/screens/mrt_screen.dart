import 'package:flutter/material.dart';
import '../models/transport_data.dart';
import '../services/lta_service.dart';
import '../widgets/ad_banner.dart';

/// MRT Station Crowd Density screen
class MrtScreen extends StatefulWidget {
  final LTAService ltaService;
  const MrtScreen({super.key, required this.ltaService});

  @override
  State<MrtScreen> createState() => _MrtScreenState();
}

class _MrtScreenState extends State<MrtScreen> {
  List<StationCrowdDensity> _stations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.ltaService.getStationCrowdDensity();
      if (data.isEmpty && mounted) {
        setState(() {
          _stations = [];
          _loading = false;
          _error = 'MRT crowd data currently unavailable from LTA.\nCheck back later — data is published periodically.';
        });
      } else {
        setState(() {
          _stations = data;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load MRT data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRT Crowd Density'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.train, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _stations.length,
                    itemBuilder: (context, index) {
                      final s = _stations[index];
                      return _MrtStationTile(station: s);
                    },
                  ),
                ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}

class _MrtStationTile extends StatelessWidget {
  final StationCrowdDensity station;
  const _MrtStationTile({required this.station});

  @override
  Widget build(BuildContext context) {
    final level = int.tryParse(station.crowdLevel) ?? 0;

    Color color;
    String icon;
    if (level <= 1) {
      color = Colors.green;
      icon = '😊';
    } else if (level == 2) {
      color = Colors.orange;
      icon = '😐';
    } else {
      color = Colors.red;
      icon = '😫';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(station.stationName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(station.platform.isNotEmpty ? station.platform : station.trainDirection),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          station.crowdLabel,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}
