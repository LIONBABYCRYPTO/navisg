import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_stop.dart';
import '../models/transport_data.dart';
import '../services/lta_service.dart';
import '../services/favorites_service.dart';

/// Smart Map screen — configurable layers: Bus Stops, MRT, Carpark, Traffic,
/// GPS locate-me, route overlay, and live arrival info sheets.
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

  // Layer toggles
  bool _showBusStops = true;
  bool _showMrt = true;
  bool _showCarpark = false;
  bool _showTraffic = false;

  // Selected point info
  String? _selectedInfo;
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
  bool _loadingGps = false;
  bool _chinese = false;

  // Carpark cache
  List<Carpark> _carparkLots = [];
  // Traffic cache
  List<TrafficIncident> _trafficIncidents = [];

  // MRT station map (deduped by name)
  late final List<_MrtPoint> _mrtPoints = _buildMrtPoints();

  static const LatLng _sgCenter = LatLng(1.3521, 103.8198);

  List<_MrtPoint> _buildMrtPoints() {
    final nameMap = <String, _MrtPoint>{};
    for (final s in singaporeMrtStations) {
      nameMap.putIfAbsent(s.name, () => _MrtPoint(name: s.name, lines: [], lat: s.latitude, lng: s.longitude));
      nameMap[s.name]!.lines.add(s.line);
    }
    return nameMap.values.toList();
  }

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
    if (serviceNo != null) _loadBusRoute(serviceNo);
    if (stopCode != null) {
      final stop = widget.allStops.where((s) => s.stopCode == stopCode).firstOrNull;
      if (stop != null) {
        setState(() {
          _selectedInfo = null;
          _selectedStop = stop;
          _routeStops = [];
          _routeServiceNo = null;
        });
        _mapController.move(LatLng(stop.latitude, stop.longitude), 14.0);
        _loadArrivals(stop.stopCode);
      }
    }
  }

  // --- Viewport filtering ---

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final bounds = camera.visibleBounds;
      setState(() {
        _filteredStops = widget.allStops.where((s) {
          return s.latitude >= bounds.south && s.latitude <= bounds.north &&
              s.longitude >= bounds.west && s.longitude <= bounds.east;
        }).toList();
      });
    });
  }

  // --- Tap handlers ---

  void _onBusStopTapped(BusStop stop) {
    setState(() {
      _selectedStop = stop;
      _selectedInfo = stop.description;
      _selectedServices = [];
      _routeStops = [];
      _routeServiceNo = null;
    });
    _mapController.move(LatLng(stop.latitude, stop.longitude), 14.0);
    _loadArrivals(stop.stopCode);
  }

  void _onMrtTapped(_MrtPoint mrt) {
    setState(() {
      _selectedInfo = '${mrt.name}: ${mrt.lines.join("/")} Line';
      _selectedStop = null;
      _selectedServices = [];
    });
    _mapController.move(LatLng(mrt.lat, mrt.lng), 14.0);
  }

  void _onCarparkTapped(Carpark cp) {
    setState(() {
      _selectedInfo =
          '🅿️ ${cp.development}: ${cp.availableLots} lots (${cp.lotTypeLabel})';
      _selectedStop = null;
      _selectedServices = [];
    });
  }

  void _onTrafficTapped(TrafficIncident ti) {
    setState(() {
      _selectedInfo = '${ti.typeLabel} — ${ti.message}';
      _selectedStop = null;
      _selectedServices = [];
    });
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

  // --- GPS ---

  Future<void> _locateMe() async {
    setState(() => _loadingGps = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_chinese ? '请开启GPS' : 'Enable GPS'), duration: const Duration(seconds: 2)),
          );
        }
        setState(() => _loadingGps = false);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          if (mounted) _showSnack(_chinese ? '需要位置权限' : 'Location permission needed');
          setState(() => _loadingGps = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
      _gpsAvailable = true;
      _mapController.move(LatLng(_lat, _lng), 15.0);
      setState(() => _loadingGps = false);
    } catch (e) {
      setState(() => _loadingGps = false);
      if (mounted) _showSnack('GPS: $e');
    }
  }

  // --- Bus Route ---

  Future<void> _loadBusRoute(String serviceNo) async {
    setState(() { _loadingRoute = true; _routeServiceNo = serviceNo; _routeStops = []; _selectedStop = null; _selectedServices = []; _selectedInfo = null; });
    final stops = await widget.ltaService.getBusRoute(serviceNo, direction: 1);
    if (stops.isNotEmpty && mounted) {
      double mLat = 90, xLat = -90, mLng = 180, xLng = -180;
      for (final s in stops) {
        mLat = s.latitude < mLat ? s.latitude : mLat;
        xLat = s.latitude > xLat ? s.latitude : xLat;
        mLng = s.longitude < mLng ? s.longitude : mLng;
        xLng = s.longitude > xLng ? s.longitude : xLng;
      }
      _mapController.move(LatLng((mLat + xLat) / 2, (mLng + xLng) / 2), 12.0);
      setState(() { _routeStops = stops; _loadingRoute = false; });
    } else if (mounted) {
      setState(() => _loadingRoute = false);
      _showSnack('Route $serviceNo ${_chinese ? "暂无数据" : "not available"}');
    }
  }

  void _showRouteSearch() {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_chinese ? '查看巴士路线' : 'View Bus Route'),
        content: TextField(controller: ctl,
          decoration: InputDecoration(labelText: _chinese ? '巴士编号 (如64)' : 'Service number (e.g. 64)',
              border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.directions_bus)),
          keyboardType: TextInputType.number, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_chinese ? '取消' : 'Cancel')),
          FilledButton(onPressed: () { Navigator.pop(ctx); if (ctl.text.trim().isNotEmpty) _loadBusRoute(ctl.text.trim()); },
              child: Text(_chinese ? '显示路线' : 'Show Route')),
        ],
      ),
    );
  }

  // --- Layer data loading ---

  Future<void> _loadCarparkData() async {
    final data = await widget.ltaService.getCarparkAvailability();
    if (mounted) setState(() => _carparkLots = data);
  }

  Future<void> _loadTrafficData() async {
    final data = await widget.ltaService.getTrafficIncidents();
    if (mounted) setState(() => _trafficIncidents = data);
  }

  void _toggleLayer(String layer) {
    setState(() {
      switch (layer) {
        case 'bus': _showBusStops = !_showBusStops; break;
        case 'mrt': _showMrt = !_showMrt; break;
        case 'carpark':
          _showCarpark = !_showCarpark;
          if (_showCarpark && _carparkLots.isEmpty) _loadCarparkData();
          break;
        case 'traffic':
          _showTraffic = !_showTraffic;
          if (_showTraffic && _trafficIncidents.isEmpty) _loadTrafficData();
          break;
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  // ====================================================================
  // BUILD
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _routeServiceNo != null
              ? '${_chinese ? "巴士" : "Bus"} $_routeServiceNo'
              : (_chinese ? '智慧地图' : 'Smart Map'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: _showRouteSearch,
            tooltip: _chinese ? '巴士路线' : 'Bus route',
          ),
          if (_routeServiceNo != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() { _routeStops = []; _routeServiceNo = null; }),
              tooltip: _chinese ? '清除' : 'Clear',
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
              onTap: (_, __) => setState(() { _selectedStop = null; _selectedServices = []; _selectedInfo = null; }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.navisg.navisg',
                maxZoom: 18,
              ),

              // GPS dot
              if (_gpsAvailable)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(_lat, _lng), width: 24, height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.3), shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 3),
                      ),
                      child: const Center(child: Icon(Icons.my_location, size: 12, color: Colors.white)),
                    ),
                  ),
                ]),

              // Bus route polyline
              if (_routeStops.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(
                    points: _routeStops.map((s) => LatLng(s.latitude, s.longitude)).toList(),
                    color: theme.colorScheme.primary.withValues(alpha: 0.7), strokeWidth: 4.0,
                  ),
                ]),

              // Route stop markers
              if (_routeStops.isNotEmpty)
                MarkerLayer(markers: _routeStops.map((s) {
                  return Marker(
                    point: LatLng(s.latitude, s.longitude), width: 22, height: 22,
                    child: GestureDetector(
                      onTap: () {
                        final stop = widget.allStops.where((bs) => bs.stopCode == s.busStopCode).firstOrNull;
                        if (stop != null) _onBusStopTapped(stop);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(child: Text('${s.stopSequence}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  );
                }).toList()),

              // MRT stations
              if (_showMrt && _routeStops.isEmpty)
                MarkerLayer(markers: _mrtPoints.where((m) =>
                    m.lat >= _mapController.camera.visibleBounds.south &&
                    m.lat <= _mapController.camera.visibleBounds.north &&
                    m.lng >= _mapController.camera.visibleBounds.west &&
                    m.lng <= _mapController.camera.visibleBounds.east).map((mrt) {
                  final color = _mrtLineColor(mrt.lines.first);
                  return Marker(
                    point: LatLng(mrt.lat, mrt.lng), width: 32, height: 32,
                    child: GestureDetector(
                      onTap: () => _onMrtTapped(mrt),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 3)],
                        ),
                        child: Center(
                          child: Text(_mrtLineAbbr(mrt.lines.first),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  );
                }).toList()),

              // Bus stops
              if (_showBusStops && _routeStops.isEmpty)
                MarkerLayer(markers: _filteredStops.map((stop) {
                  final isSelected = _selectedStop?.stopCode == stop.stopCode;
                  final sz = isSelected ? 40.0 : 28.0;
                  return Marker(
                    point: LatLng(stop.latitude, stop.longitude), width: sz, height: sz,
                    child: GestureDetector(
                      onTap: () => _onBusStopTapped(stop),
                      child: Icon(Icons.directions_bus,
                          color: isSelected ? Colors.orange : Colors.teal,
                          size: sz - 4),
                    ),
                  );
                }).toList()),

              // Carpark markers
              if (_showCarpark && _carparkLots.isNotEmpty && _routeStops.isEmpty)
                MarkerLayer(markers: _carparkLots.where((cp) =>
                    cp.latitude >= _mapController.camera.visibleBounds.south &&
                    cp.latitude <= _mapController.camera.visibleBounds.north &&
                    cp.longitude >= _mapController.camera.visibleBounds.west &&
                    cp.longitude <= _mapController.camera.visibleBounds.east).map((cp) {
                  Color c;
                  switch (cp.availabilityStatus) {
                    case 'plenty': c = Colors.green; break;
                    case 'limited': c = Colors.orange; break;
                    default: c = Colors.red;
                  }
                  return Marker(
                    point: LatLng(cp.latitude, cp.longitude), width: 24, height: 24,
                    child: GestureDetector(
                      onTap: () => _onCarparkTapped(cp),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(child: Text('${cp.availableLots}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  );
                }).toList()),

              // Traffic markers
              if (_showTraffic && _trafficIncidents.isNotEmpty && _routeStops.isEmpty)
                MarkerLayer(markers: _trafficIncidents.where((ti) =>
                    ti.latitude != null && ti.longitude != null &&
                    ti.latitude! >= _mapController.camera.visibleBounds.south &&
                    ti.latitude! <= _mapController.camera.visibleBounds.north &&
                    ti.longitude! >= _mapController.camera.visibleBounds.west &&
                    ti.longitude! <= _mapController.camera.visibleBounds.east
                ).map((ti) {
                  return Marker(
                    point: LatLng(ti.latitude!, ti.longitude!), width: 28, height: 28,
                    child: GestureDetector(
                      onTap: () => _onTrafficTapped(ti),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade700, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(child: const Icon(Icons.warning, color: Colors.white, size: 16)),
                      ),
                    ),
                  );
                }).toList()),
            ],
          ),

          // Route loading
          if (_loadingRoute)
            Positioned(top: 8, left: 0, right: 0, child: Center(
              child: Card(child: Padding(padding: const EdgeInsets.all(12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10), Text(_chinese ? '加载路线中...' : 'Loading route...'),
                ])),
              ),
            )),

          // Info sheet or route bar
          if (_routeStops.isNotEmpty)
            _buildRouteInfoBar(),
          if (_routeStops.isEmpty && (_selectedStop != null || _selectedInfo != null))
            _buildInfoSheet(),

          // Zoom + locate controls
          Positioned(right: 8, bottom: 80, child: Column(children: [
            _fab(Icons.add, () => _mapController.move(_mapController.camera.center, (_mapController.camera.zoom + 1).clamp(5, 18))),
            const SizedBox(height: 8),
            _fab(Icons.remove, () => _mapController.move(_mapController.camera.center, (_mapController.camera.zoom - 1).clamp(5, 18))),
            const SizedBox(height: 8),
            _fab(_gpsAvailable ? Icons.my_location : Icons.location_disabled, _locateMe,
                isLoading: _loadingGps, color: _gpsAvailable ? Colors.blue : null),
          ])),

          // Layer toggle bar (bottom-left)
          Positioned(left: 12, bottom: 16, child: _buildLayerToggles()),
        ],
      ),
    );
  }

  Widget _fab(IconData icon, VoidCallback onTap, {bool isLoading = false, Color? color}) {
    return FloatingActionButton.small(
      heroTag: UniqueKey().toString(),
      onPressed: isLoading ? null : onTap,
      child: isLoading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, color: color),
    );
  }

  // --- Layer toggle panel ---

  Widget _buildLayerToggles() {
    final toggles = <_LayerToggle>[
      _LayerToggle('🚌', 'Bus', _showBusStops, 'bus'),
      _LayerToggle('🚇', 'MRT', _showMrt, 'mrt'),
      _LayerToggle('🅿️', 'Park', _showCarpark, 'carpark'),
      _LayerToggle('⚠️', 'Traffic', _showTraffic, 'traffic'),
    ];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: toggles.map((t) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: GestureDetector(
              onTap: () => _toggleLayer(t.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.active ? _layerBgColor(t.key) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(t.label, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: t.active ? Colors.white : Colors.grey,
                  )),
                ]),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }

  Color _layerBgColor(String key) {
    switch (key) {
      case 'bus': return Colors.teal.withValues(alpha: 0.2);
      case 'mrt': return Colors.deepPurple.withValues(alpha: 0.2);
      case 'carpark': return Colors.green.withValues(alpha: 0.2);
      case 'traffic': return Colors.red.withValues(alpha: 0.2);
      default: return Colors.grey.withValues(alpha: 0.2);
    }
  }

  // --- Info bottom sheet ---

  Widget _buildInfoSheet() {
    if (_selectedStop != null && _selectedServices.isNotEmpty) {
      return _buildArrivalSheet();
    }
    // Generic info card
    if (_selectedInfo != null && _selectedStop == null) {
      return Positioned(left: 12, right: 12, bottom: 12, child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: Text(_selectedInfo!, style: const TextStyle(fontWeight: FontWeight.w500))),
            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() { _selectedInfo = null; })),
          ]),
        ),
      ));
    }
    return const SizedBox.shrink();
  }

  Widget _buildArrivalSheet() {
    final theme = Theme.of(context);
    return Positioned(left: 0, right: 0, bottom: 0, child: Card(
      margin: const EdgeInsets.all(8),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 280,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(margin: const EdgeInsets.only(top: 6), width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          // Header
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 0), child: Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
              child: Text(_selectedStop!.stopCode,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onPrimaryContainer))),
            const SizedBox(width: 10),
            Expanded(child: Text(_selectedStop!.description,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis)),
            IconButton(icon: const Icon(Icons.star_border, size: 20), tooltip: _chinese ? '收藏' : 'Save',
                onPressed: _saveStopFromMap, visualDensity: VisualDensity.compact),
            IconButton(icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() { _selectedStop = null; _selectedServices = []; }),
                visualDensity: VisualDensity.compact),
          ])),
          const Divider(height: 1),
          // Arrivals
          Expanded(child: _loadingArrivals
              ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : _selectedServices.isEmpty
                  ? Center(child: Text(_chinese ? '暂无巴士信息' : 'No buses', style: TextStyle(color: Colors.grey.shade500)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _selectedServices.length,
                      itemBuilder: (ctx, i) => _renderServiceRow(_selectedServices[i]),
                    )),
        ]),
      ),
    ));
  }

  Widget _renderServiceRow(BusService svc) {
    final Color opColor;
    switch (svc.operator) {
      case 'SBST': opColor = Colors.red; break;
      case 'SMRT': opColor = Colors.deepPurple; break;
      case 'TTS': opColor = Colors.orange; break;
      case 'GAS': opColor = Colors.teal; break;
      default: opColor = Colors.grey;
    }
    return InkWell(
      onTap: () { _loadBusRoute(svc.serviceNo); },
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Row(children: [
          Container(width: 36, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: opColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(svc.serviceNo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: opColor))),
          const SizedBox(width: 8),
          _arrTime('1st', svc.nextBus),
          _arrTime('2nd', svc.nextBus2),
          _arrTime('3rd', svc.nextBus3),
          if (svc.nextBus?.isWheelchairAccessible == true || svc.nextBus2?.isWheelchairAccessible == true)
            const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.accessible, size: 16, color: Colors.blue)),
          const SizedBox(width: 4),
          const Icon(Icons.route, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _arrTime(String label, BusArrivalInfo? info) {
    final mins = info?.minutesUntilArrival;
    String display; Color color;
    if (info == null || info.monitored == 0 || mins == null || mins < 0) {
      display = '-'; color = Colors.grey;
    } else if (mins == 0) {
      display = 'Arr'; color = Colors.green;
    } else if (mins <= 3) {
      display = '${mins}m'; color = Colors.orange.shade700;
    } else {
      display = '${mins}m'; color = Colors.black87;
    }
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      Text(display, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
    ]));
  }

  // --- Route info bar ---

  Widget _buildRouteInfoBar() {
    final theme = Theme.of(context);
    return Positioned(left: 8, right: 8, bottom: 8, child: Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
            child: Text(_routeServiceNo!,
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer))),
          const SizedBox(width: 12),
          Expanded(child: Text('${_routeStops.first.roadName} → ${_routeStops.last.roadName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
          Text('${_routeStops.length} ${_chinese ? "站" : "stops"}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ),
    ));
  }

  // --- Save stop ---

  Future<void> _saveStopFromMap() async {
    if (_selectedStop == null) return;
    final fs = FavoritesService();
    await fs.addFavorite(_selectedStop!);
    if (mounted) _showSnack(_chinese ? '已收藏 ${_selectedStop!.description}' : 'Saved ${_selectedStop!.description}');
  }

  // --- MRT helpers ---

  Color _mrtLineColor(String line) {
    switch (line) {
      case 'NS': return const Color(0xFFD42E12);
      case 'EW': return const Color(0xFF009645);
      case 'NE': return const Color(0xFF9900AA);
      case 'CC': return const Color(0xFFFFA100);
      case 'DT': return const Color(0xFF005EC4);
      case 'TE': return const Color(0xFF9D5B25);
      case 'CG': return const Color(0xFF009645);
      case 'LRT': return const Color(0xFF878787);
      default: return Colors.grey;
    }
  }

  String _mrtLineAbbr(String line) {
    switch (line) {
      case 'NS': case 'EW': case 'NE': case 'CC': case 'DT': case 'TE': case 'CG': return line;
      case 'LRT': return 'L';
      default: return '?';
    }
  }
}

/// Internal MRT point model (deduped by name for shared stations)
class _MrtPoint {
  final String name;
  final List<String> lines;
  final double lat;
  final double lng;
  _MrtPoint({required this.name, required this.lines, required this.lat, required this.lng});
}

/// Helper for layer toggle list
class _LayerToggle {
  final String icon;
  final String label;
  final bool active;
  final String key;
  _LayerToggle(this.icon, this.label, this.active, this.key);
}
