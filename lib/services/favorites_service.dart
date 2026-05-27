import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_stop.dart';

/// Manages user's saved/favorite bus stops locally.
/// Supports reordering with moveFavorite().
class FavoritesService {
  static const String _storageKey = 'navisg_favorites';

  /// Load saved favorite stops from local storage
  Future<List<BusStop>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json == null || json.isEmpty) return [];

      final list = jsonDecode(json) as List;
      return list
          .map((e) => BusStop.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      return [];
    }
  }

  /// Save a stop as favorite
  Future<void> addFavorite(BusStop stop) async {
    final stops = await getFavorites();
    if (stops.any((s) => s.stopCode == stop.stopCode)) return;
    stops.add(stop);
    await _save(stops);
  }

  /// Remove a stop from favorites
  Future<void> removeFavorite(String stopCode) async {
    final stops = await getFavorites();
    stops.removeWhere((s) => s.stopCode == stopCode);
    await _save(stops);
  }

  /// Reorder: move item at [oldIndex] to [newIndex]
  Future<void> moveFavorite(int oldIndex, int newIndex) async {
    final stops = await getFavorites();
    if (oldIndex < 0 || oldIndex >= stops.length) return;
    if (newIndex < 0 || newIndex > stops.length) return;

    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);
    await _save(stops);
  }

  /// Check if a stop is favorited
  Future<bool> isFavorite(String stopCode) async {
    final stops = await getFavorites();
    return stops.any((s) => s.stopCode == stopCode);
  }

  Future<void> _save(List<BusStop> stops) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(stops.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
