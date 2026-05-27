import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/bus_stop.dart';

/// Service for interacting with LTA DataMall APIs.
/// Uses the user's LTA API key for authentication.
class LTAService {
  static const String _baseUrl = 'http://datamall2.mytransport.sg/ltaodataservice';

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
}
