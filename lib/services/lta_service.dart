import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/bus_stop.dart';
import '../models/transport_data.dart';

/// Service for interacting with LTA DataMall APIs.
/// Uses the user's LTA API key for authentication.
class LTAService {
  static const String _baseUrl = 'https://datamall2.mytransport.sg/ltaodataservice';

  final String _apiKey;
  final HttpClient _client;

  LTAService(this._apiKey)
      : _client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 10);

  /// Fetches real-time bus arrivals for a given bus stop.
  /// Returns list of BusService objects with arrival info.
  Future<List<BusService>> getBusArrival(String busStopCode,
      {String? serviceNo}) async {
    try {
      final params = {'BusStopCode': busStopCode};
      if (serviceNo != null && serviceNo.isNotEmpty) {
        params['ServiceNo'] = serviceNo;
      }

      final uri = Uri.parse('$_baseUrl/v3/BusArrival')
          .replace(queryParameters: params);
      final request = await _client.getUrl(uri);
      request.headers.set('AccountKey', _apiKey);
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        final services = (data['Services'] as List? ?? [])
            .map((s) => BusService.fromJson(s as Map<String, dynamic>))
            .toList();
        return services;
      } else {
        debugPrint('LTA API error: ${response.statusCode} - $body');
        return [];
      }
    } catch (e) {
      debugPrint('LTA API exception: $e');
      return [];
    }
  }

  /// Fetches all bus stops near given coordinates.
  /// Note: LTA doesn't have a "nearby" endpoint, so we fetch all stops
  /// and filter client-side. For production, consider caching the full list.
  Future<List<BusStop>> getBusStops() async {
    try {
      final allStops = <BusStop>[];
      var skip = 0;
      const limit = 500;

      while (true) {
        final uri = Uri.parse('$_baseUrl/BusStops')
            .replace(queryParameters: {'\$skip': skip.toString()});

        final request = await _client.getUrl(uri);
        request.headers.set('AccountKey', _apiKey);
        request.headers.set('Accept', 'application/json');

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = json.decode(body) as Map<String, dynamic>;
          final stops = (data['value'] as List? ?? [])
              .map((s) => BusStop.fromJson(s as Map<String, dynamic>))
              .toList();

          allStops.addAll(stops);

          if (stops.length < limit) break;
          skip += limit;
        } else {
          break;
        }
      }

      return allStops;
    } catch (e) {
      debugPrint('LTA getBusStops exception: $e');
      return [];
    }
  }

  /// Search bus stops by text (code or description).
  Future<List<BusStop>> searchBusStops(String query,
      {List<BusStop>? cachedStops}) async {
    if (query.length < 2) return [];
    final q = query.toUpperCase();

    // If cached stops provided, search locally
    if (cachedStops != null) {
      return cachedStops.where((stop) {
        return stop.stopCode.contains(q) ||
            stop.description.toUpperCase().contains(q);
      }).toList();
    }

    // Otherwise fetch from API (only exact stop code search supported)
    try {
      final uri = Uri.parse('$_baseUrl/BusStops')
          .replace(queryParameters: {'\$skip': '0'});
      final request = await _client.getUrl(uri);
      request.headers.set('AccountKey', _apiKey);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        final stops = (data['value'] as List? ?? [])
            .map((s) => BusStop.fromJson(s as Map<String, dynamic>))
            .where((s) =>
                s.stopCode.contains(q) ||
                s.description.toUpperCase().contains(q))
            .toList();
        return stops;
      }
    } catch (e) {
      debugPrint('LTA search exception: $e');
    }
    return [];
  }

  // ===================================================================
  // Phase 2 APIs
  // ===================================================================

  /// Fetches car park availability data.
  Future<List<Carpark>> getCarparkAvailability() async {
    try {
      final allLots = <Carpark>[];
      var skip = 0;
      const limit = 500;

      while (true) {
        final uri = Uri.parse('$_baseUrl/CarParkAvailabilityv2')
            .replace(queryParameters: {'\$skip': skip.toString()});
        final request = await _client.getUrl(uri);
        request.headers.set('AccountKey', _apiKey);
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200) {
          final data = json.decode(body) as Map<String, dynamic>;
          final lots = (data['value'] as List? ?? [])
              .map((l) => Carpark.fromJson(l as Map<String, dynamic>))
              .toList();
          allLots.addAll(lots);
          if (lots.length < limit) break;
          skip += limit;
        } else {
          break;
        }
      }
      return allLots;
    } catch (e) {
      debugPrint('LTA getCarparkAvailability exception: $e');
      return [];
    }
  }

  /// Fetches MRT/LRT station crowd density.
  Future<List<StationCrowdDensity>> getStationCrowdDensity() async {
    try {
      final uri = Uri.parse('$_baseUrl/PCDRealTime');
      final request = await _client.getUrl(uri);
      request.headers.set('AccountKey', _apiKey);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        final value = data['value'];
        if (value is Map && value['status'] != null) {
          // API returned error status
          debugPrint('PCD API status: ${value['status']}');
          return [];
        }
        if (value is List) {
          return value
              .map((s) =>
                  StationCrowdDensity.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('LTA getStationCrowdDensity exception: $e');
      return [];
    }
  }

  /// Fetches traffic incidents (accidents, road works, etc.)
  Future<List<TrafficIncident>> getTrafficIncidents() async {
    try {
      final uri = Uri.parse('$_baseUrl/TrafficIncident');
      final request = await _client.getUrl(uri);
      request.headers.set('AccountKey', _apiKey);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        return (data['value'] as List? ?? [])
            .map((i) => TrafficIncident.fromJson(i as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('LTA getTrafficIncidents exception: $e');
      return [];
    }
  }

  // ===================================================================
  // Bus Routes
  // ===================================================================

  /// Fetches bus route (sequence of stops) for a given service number.
  /// Direction: 1=forward, 2=backward.
  Future<List<BusRouteStop>> getBusRoute(String serviceNo, {int direction = 1}) async {
    try {
      final uri = Uri.parse('$_baseUrl/BusRoutes')
          .replace(queryParameters: {
            '\$skip': '0',
            'ServiceNo': serviceNo,
          });
      final request = await _client.getUrl(uri);
      request.headers.set('AccountKey', _apiKey);
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final data = json.decode(body) as Map<String, dynamic>;
        final allStops = (data['value'] as List? ?? [])
            .map((s) => BusRouteStop.fromJson(s as Map<String, dynamic>))
            .where((s) => s.direction == direction)
            .toList();
        allStops.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
        return allStops;
      }
      return [];
    } catch (e) {
      debugPrint('LTA getBusRoute exception: $e');
      return [];
    }
  }
}
