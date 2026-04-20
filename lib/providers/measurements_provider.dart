import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/database_service.dart';
import '../services/geocoding_service.dart';

enum DateRange { d7, d30, d90 }

extension DateRangeLabel on DateRange {
  String get label {
    switch (this) {
      case DateRange.d7:
        return '7 วัน';
      case DateRange.d30:
        return '30 วัน';
      case DateRange.d90:
        return '90 วัน';
    }
  }

  DateTime get fromDate {
    final now = DateTime.now();
    switch (this) {
      case DateRange.d7:
        return now.subtract(const Duration(days: 7));
      case DateRange.d30:
        return now.subtract(const Duration(days: 30));
      case DateRange.d90:
        return now.subtract(const Duration(days: 90));
    }
  }
}

class MeasurementsProvider extends ChangeNotifier {
  List<MeasurementRecord> _measurements = [];
  bool _loading = false;
  String? _error;
  DateRange _dateRange = DateRange.d30;
  String? _selectedLocation;
  final Map<String, String> _locationNames = {};

  List<MeasurementRecord> get measurements => _measurements;
  bool get loading => _loading;
  String? get error => _error;
  DateRange get dateRange => _dateRange;
  String? get selectedLocation => _selectedLocation;
  
  String getLocationName(String locKey) => _locationNames[locKey] ?? locKey;

  List<String> get uniqueLocations {
    final locations = _measurements
        .where((m) => m.lat != 0 || m.lng != 0)
        .map((m) => '${m.lat.toStringAsFixed(4)}, ${m.lng.toStringAsFixed(4)}')
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  List<MeasurementRecord> get filteredMeasurements {
    if (_selectedLocation == null) return _measurements;
    return _measurements.where((m) {
      final loc = '${m.lat.toStringAsFixed(4)}, ${m.lng.toStringAsFixed(4)}';
      return loc == _selectedLocation;
    }).toList();
  }

  void setDateRange(DateRange range) {
    _dateRange = range;
    notifyListeners();
    fetch();
  }

  void setLocation(String? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void clearLocationFilter() {
    _selectedLocation = null;
    notifyListeners();
  }

  Future<void> fetch() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _measurements =
          await DatabaseService.getMeasurements(from: _dateRange.fromDate);
      _resolveLocationNames();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดประวัติข้อมูล';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _resolveLocationNames() async {
    for (final loc in uniqueLocations) {
      if (_locationNames.containsKey(loc)) continue;
      try {
        final parts = loc.split(', ');
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        final address = await GeocodingService.getAddress(lat, lng);
        _locationNames[loc] = address;
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> remove(String id) async {
    try {
      await DatabaseService.deleteMeasurement(id);
      _measurements = _measurements.where((m) => m.id != id).toList();
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการลบข้อมูล';
      notifyListeners();
    }
  }
}
