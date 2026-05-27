import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved favorite: bus service + stop combination
class FavoriteRoute {
  final String serviceNo;
  final String stopCode;
  final String stopName;

  FavoriteRoute({
    required this.serviceNo,
    required this.stopCode,
    required this.stopName,
  });

  Map<String, dynamic> toJson() => {
        'serviceNo': serviceNo,
        'stopCode': stopCode,
        'stopName': stopName,
      };

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      serviceNo: json['serviceNo'] ?? '',
      stopCode: json['stopCode'] ?? '',
      stopName: json['stopName'] ?? '',
    );
  }
}

/// Manages favorite bus route + stop combinations.
class FavoriteRoutesService {
  static const String _storageKey = 'navisg_favorite_routes';

  Future<List<FavoriteRoute>> getRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((e) => FavoriteRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading favorite routes: $e');
      return [];
    }
  }

  Future<void> addRoute(FavoriteRoute route) async {
    final routes = await getRoutes();
    if (routes.any((r) =>
        r.serviceNo == route.serviceNo && r.stopCode == route.stopCode)) {
      return; // already exists
    }
    routes.add(route);
    await _save(routes);
  }

  Future<void> removeRoute(String serviceNo, String stopCode) async {
    final routes = await getRoutes();
    routes.removeWhere(
        (r) => r.serviceNo == serviceNo && r.stopCode == stopCode);
    await _save(routes);
  }

  Future<bool> isRouteSaved(String serviceNo, String stopCode) async {
    final routes = await getRoutes();
    return routes
        .any((r) => r.serviceNo == serviceNo && r.stopCode == stopCode);
  }

  Future<void> _save(List<FavoriteRoute> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(routes.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
