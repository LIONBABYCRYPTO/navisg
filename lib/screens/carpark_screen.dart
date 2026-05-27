import 'package:flutter/material.dart';
import '../models/transport_data.dart';
import '../models/bus_stop.dart';
import '../services/lta_service.dart';
import '../widgets/ad_banner.dart';
import 'settings_screen.dart';

/// Carpark Availability screen
class CarparkScreen extends StatefulWidget {
  final LTAService ltaService;
  final List<BusStop> allStops;

  const CarparkScreen({super.key, required this.ltaService, this.allStops = const []});

  @override
  State<CarparkScreen> createState() => _CarparkScreenState();
}

class _CarparkScreenState extends State<CarparkScreen> {
  List<Carpark> _allCarparks = [];
  List<Carpark> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  List<String> _areas = [];
  String _filterArea = 'All';
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final carparks = await widget.ltaService.getCarparkAvailability();
    final areas = carparks.map((c) => c.area).toSet().toList()..sort();
    setState(() {
      _allCarparks = carparks;
      _areas = areas;
      _applyFilters();
      _loading = false;
      _lastUpdated = DateTime.now();
    });
  }

  void _applyFilters() {
    var list = _allCarparks;
    if (_filterArea != 'All') {
      list = list.where((c) => c.area == _filterArea).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.development.toLowerCase().contains(q) ||
              c.area.toLowerCase().contains(q))
          .toList();
    }
    list.sort((a, b) => a.area.compareTo(b.area));
    setState(() => _filtered = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carpark Availability'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
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
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search carparks...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) {
                      _searchQuery = v;
                      _applyFilters();
                    },
                  ),
                ),
                // Area filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: ['All', ..._areas].map((area) {
                      final active = area == _filterArea;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(area),
                          selected: active,
                          onSelected: (_) {
                            _filterArea = area;
                            _applyFilters();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                // Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        '${_filtered.length} carparks · ${_filtered.fold<int>(0, (s, c) => s + c.availableLots)} total lots',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const Spacer(),
                      if (_lastUpdated != null)
                        Text(
                          'Updated ${_timeAgo(_lastUpdated!)}',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                // List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final cp = _filtered[index];
                        return _CarparkTile(carpark: cp);
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AdBanner(),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes == 1) return '1 min ago';
    return '${diff.inMinutes} min ago';
  }
}

class _CarparkTile extends StatelessWidget {
  final Carpark carpark;
  const _CarparkTile({required this.carpark});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (carpark.availableLots > 100) {
      statusColor = Colors.green;
    } else if (carpark.availableLots > 20) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.red;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Text(
          _abbreviate(carpark.development),
          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 11),
        ),
      ),
      title: Text(carpark.development, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${carpark.area} · ${carpark.lotTypeLabel}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${carpark.availableLots}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: statusColor,
            ),
          ),
          Text('lots', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _abbreviate(String name) {
    if (name.length <= 3) return name;
    return name.split(' ').map((w) => w[0]).take(2).join();
  }
}
