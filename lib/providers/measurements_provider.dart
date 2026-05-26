import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';

// ─── Date Range Filter ───────────────────────────────────────────────

enum DateRange { d7, d30, d90, all, custom }

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
      case DateRange.custom:
        return 'เลือกช่วงเวลา';
    }
  }

  DateTime? get fromDate {
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
      case DateRange.custom:
        return null;
    }
  }
}

// ─── Provider ────────────────────────────────────────────────────────

class MeasurementsProvider extends ChangeNotifier {
  static const int _pageSize = 15;

  // — Paginated list (for History screen) —
  List<PlotRecord> _plots = [];

  // — Full list (for Map / Dashboard / Export) —
  List<PlotRecord> _allPlots = [];

  // — State —
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;
  String? _error;
  DateRange _dateRange = DateRange.d30;

  DateTime? _customFrom;
  DateTime? _customTo;

  // — Getters —
  List<PlotRecord> get plots => _plots;
  List<PlotRecord> get allPlots => _allPlots;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;
  String? get error => _error;
  DateRange get dateRange => _dateRange;
  DateTime? get customFrom => _customFrom;
  DateTime? get customTo => _customTo;

  DateTime? get currentFrom {
    if (_dateRange == DateRange.custom) return _customFrom;
    return _dateRange.fromDate;
  }

  DateTime? get currentTo {
    if (_dateRange == DateRange.custom && _customTo != null) {
      return DateTime(_customTo!.year, _customTo!.month, _customTo!.day, 23, 59, 59);
    }
    return null;
  }

  // — Actions —

  void setDateRange(DateRange range) {
    _dateRange = range;
    if (range != DateRange.custom || (_customFrom != null && _customTo != null)) {
      fetch();
    } else {
      notifyListeners();
    }
  }

  void setCustomRange(DateTime from, DateTime to) {
    _dateRange = DateRange.custom;
    _customFrom = from;
    _customTo = to;
    fetch();
  }

  /// Initial fetch: loads first page + full list for map/export, counts total.
  Future<void> fetch() async {
    if (_dateRange == DateRange.custom && (_customFrom == null || _customTo == null)) {
      _plots = [];
      _allPlots = [];
      _totalCount = 0;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    _hasMore = true;
    notifyListeners();

    try {
      final cFrom = currentFrom;
      final cTo = currentTo;

      _totalCount = await ApiService.getPlotsCount(
        from: cFrom,
        to: cTo,
      );

      // Paginated list (first page)
      _plots = await ApiService.getPlots(
        from: cFrom,
        to: cTo,
        limit: _pageSize,
        offset: 0,
      );

      // Full list (map pins, export, dashboard)
      _allPlots = await ApiService.getPlots(
        from: cFrom,
        to: cTo,
      );

      _hasMore = _plots.length >= _pageSize;
    } catch (e) {
      _error = 'เกิดข้อผิดพลาด: $e';
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
      final more = await ApiService.getPlots(
        from: currentFrom,
        to: currentTo,
        limit: _pageSize,
        offset: _plots.length,
      );
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _plots.addAll(more);
        _hasMore = more.length >= _pageSize;
      }
    } catch (_) {
      // Silently fail — keep existing data visible
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  /// Delete a plot.
  Future<void> remove(String id) async {
    try {
      await ApiService.deletePlot(id);
      _plots = _plots.where((p) => p.id != id).toList();
      _allPlots = _allPlots.where((p) => p.id != id).toList();
      _totalCount = (_totalCount - 1).clamp(0, _totalCount);
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการลบข้อมูล';
      notifyListeners();
    }
  }
}
