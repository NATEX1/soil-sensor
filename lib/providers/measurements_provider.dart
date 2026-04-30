import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/database_service.dart';

// ─── Date Range Filter ───────────────────────────────────────────────

enum DateRange { d7, d30, d90, all }

extension DateRangeLabel on DateRange {
  String get label {
    switch (this) {
      case DateRange.d7:
        return '7 วัน';
      case DateRange.d30:
        return '30 วัน';
      case DateRange.d90:
        return '90 วัน';
      case DateRange.all:
        return 'ทั้งหมด';
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
      case DateRange.all:
        return DateTime(2000);
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────

class MeasurementsProvider extends ChangeNotifier {
  static const int _pageSize = 15;

  // — Paginated list (for History screen) —
  List<MeasurementRecord> _measurements = [];

  // — Full list (for Map / Dashboard / Export) —
  List<MeasurementRecord> _allMeasurements = [];

  // — State —
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;
  String? _error;
  DateRange _dateRange = DateRange.d30;

  // — Getters —
  List<MeasurementRecord> get measurements => _measurements;
  List<MeasurementRecord> get allMeasurements => _allMeasurements;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;
  String? get error => _error;
  DateRange get dateRange => _dateRange;

  // — Actions —

  void setDateRange(DateRange range) {
    _dateRange = range;
    notifyListeners();
    fetch();
  }

  /// Initial fetch: loads first page + full list for map/export, counts total.
  Future<void> fetch() async {
    _loading = true;
    _error = null;
    _hasMore = true;
    notifyListeners();

    try {
      // Count total records in the selected range
      final db = await DatabaseService.database;
      final countRes = await db.rawQuery(
        'SELECT COUNT(*) as count FROM measurements WHERE measured_at >= ?',
        [_dateRange.fromDate.toIso8601String()],
      );
      _totalCount = (countRes.first['count'] as int?) ?? 0;

      // Paginated list (first page)
      _measurements = await DatabaseService.getMeasurements(
        from: _dateRange.fromDate,
        limit: _pageSize,
        offset: 0,
      );

      // Full list (map pins, export, dashboard)
      _allMeasurements = await DatabaseService.getMeasurements(
        from: _dateRange.fromDate,
      );

      _hasMore = _measurements.length >= _pageSize;
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดประวัติข้อมูล';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Load next page (infinite scroll).
  Future<void> fetchMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final more = await DatabaseService.getMeasurements(
        from: _dateRange.fromDate,
        limit: _pageSize,
        offset: _measurements.length,
      );
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _measurements.addAll(more);
        _hasMore = more.length >= _pageSize;
      }
    } catch (_) {
      // Silently fail — keep existing data visible
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Delete a single measurement.
  Future<void> remove(String id) async {
    try {
      await DatabaseService.deleteMeasurement(id);
      _measurements = _measurements.where((m) => m.id != id).toList();
      _allMeasurements = _allMeasurements.where((m) => m.id != id).toList();
      _totalCount = (_totalCount - 1).clamp(0, _totalCount);
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการลบข้อมูล';
      notifyListeners();
    }
  }
}
