import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';

class PlotProvider extends ChangeNotifier {
  PlotRecord? _currentPlot;
  List<PlotRecord> _availablePlots = [];
  bool _isLoading = false;
  String? _error;

  PlotRecord? get currentPlot => _currentPlot;
  List<PlotRecord> get availablePlots => _availablePlots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlotProvider() {
    loadAvailablePlots();
  }

  /// Load all existing plots from DB for selection.
  Future<void> loadAvailablePlots() async {
    _setLoading(true);
    try {
      _availablePlots = await ApiService.getPlots();
      // Auto-select the most recent plot if none selected
      if (_currentPlot == null && _availablePlots.isNotEmpty) {
        _currentPlot = _availablePlots.first;
      }
    } catch (e) {
      _error = 'Failed to load plots: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Select an existing plot as the active plot.
  void selectPlot(PlotRecord plot) {
    _currentPlot = plot;
    notifyListeners();
  }

  /// Create a new plot, set it as current, and refresh the list.
  Future<PlotRecord?> startNewPlot(String name, {String? notes, double? lat, double? lng}) async {
    _setLoading(true);
    try {
      final id = await ApiService.createPlot(name, notes: notes, lat: lat, lng: lng);
      final newPlot = PlotRecord(
        id: id,
        name: name,
        createdAt: DateTime.now(),
        notes: notes,
        lat: lat,
        lng: lng,
        measurements: [],
        ph: 0, nitrogen: 0, phosphorus: 0, potassium: 0,
        moisture: 0, temperature: 0, ec: 0, salinity: 0,
      );
      _currentPlot = newPlot;
      // Add to top of available list
      _availablePlots.insert(0, newPlot);
      notifyListeners();
      return newPlot;
    } catch (e) {
      _error = 'Failed to create plot: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      // Don't call _setLoading here to avoid double notifyListeners
    }
  }

  Future<void> refreshCurrentPlot() async {
    if (_currentPlot == null) return;
    _setLoading(true);
    try {
      final plots = await ApiService.getPlots();
      _availablePlots = plots;
      final updated = plots.where((p) => p.id == _currentPlot!.id).firstOrNull;
      if (updated != null) {
        _currentPlot = updated;
      }
    } catch (e) {
      _error = 'Failed to refresh plot: $e';
    } finally {
      _setLoading(false);
    }
  }

  void clearCurrentPlot() {
    _currentPlot = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
