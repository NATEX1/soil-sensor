import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';
import '../theme/app_colors.dart';

const _sensorKeys = [
  'ph',
  'nitrogen',
  'phosphorus',
  'potassium',
  'moisture',
  'temperature',
  'ec',
  'salinity'
];

class RecommendScreen extends StatelessWidget {
  final MeasurementRecord? record;
  const RecommendScreen({super.key, this.record});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final SensorData? data = record ?? ble.sensorData;
    final isHistorical = record != null;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: data == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_off, size: 48, color: context.colors.textMuted),
                  const SizedBox(height: 12),
                  Text('ไม่มีข้อมูลเซ็นเซอร์\nกรุณาเชื่อมต่ออุปกรณ์หรือกลับสู่หน้าจอหลัก',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textMuted)),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(foregroundColor: context.colors.primaryBtn),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('กลับ'),
                  ),
                ],
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
              children: [
                // Minimal Navigation Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.colors.textNormal),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Title
                Text('คำแนะนำ\nการปรับปรุงดิน',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textNormal,
                        height: 1.2,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                    isHistorical && record!.measuredAt != null
                        ? 'ข้อมูลวันที่ ${record!.measuredAt!.day.toString().padLeft(2, '0')}/${record!.measuredAt!.month.toString().padLeft(2, '0')}/${record!.measuredAt!.year} ${record!.measuredAt!.hour.toString().padLeft(2, '0')}:${record!.measuredAt!.minute.toString().padLeft(2, '0')}'
                        : 'อ้างอิงจากค่าที่วัดได้ล่าสุด',
                    style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                if (isHistorical) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.eco, size: 14, color: context.colors.primaryBtn),
                      const SizedBox(width: 4),
                      Text('พืชที่ปลูก: ${record!.plantName}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.primaryBtn)),
                      if (record!.pointName != null && record!.pointName!.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.location_on, size: 14, color: context.colors.textMuted),
                        const SizedBox(width: 4),
                        Text(record!.pointName!,
                            style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                ..._sensorKeys.map((key) => _RecommendCard(
                      sensorKey: key,
                      value: data[key],
                    )),
              ],
            ),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final String sensorKey;
  final double value;

  const _RecommendCard({required this.sensorKey, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = getSoilStatus(sensorKey, value);
    final threshold = thresholds[sensorKey]!;
    final label = sensorLabels[sensorKey] ?? sensorKey;
    final unit = threshold.unit;
    final recommendation = recommendations[sensorKey]?[status] ?? '';
    final config = _statusConfig(status, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with subtle badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textNormal)),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // Big value display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: config.text),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(unit,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: config.text.withValues(alpha: 0.6))),
                  ),
                ],
                const Spacer(),
                Text(
                  'เกณฑ์: ${threshold.low.toStringAsFixed(threshold.low == threshold.low.roundToDouble() ? 0 : 1)}'
                  ' – ${threshold.high.toStringAsFixed(threshold.high == threshold.high.roundToDouble() ? 0 : 1)}'
                  '${unit.isNotEmpty ? " $unit" : ""}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: config.text.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: config.border.withValues(alpha: 0.3)),

          // Recommendation text area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: config.border.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: config.text.withValues(alpha: 0.8)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('คำแนะนำ',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: config.text.withValues(alpha: 0.8))),
                      const SizedBox(height: 4),
                      Text(recommendation,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.colors.textNormal,
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SoilStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _statusConfig(status, isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.border.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: config.text),
          const SizedBox(width: 4),
          Text(statusLabels[status]!,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: config.text)),
        ],
      ),
    );
  }
}

IconData _statusIcon(SoilStatus status) {
  switch (status) {
    case SoilStatus.low:
      return Icons.arrow_downward;
    case SoilStatus.normal:
      return Icons.check_circle;
    case SoilStatus.high:
      return Icons.arrow_upward;
  }
}

class _StatusConfig {
  final Color bg;
  final Color border;
  final Color text;
  const _StatusConfig({required this.bg, required this.border, required this.text});
}

_StatusConfig _statusConfig(SoilStatus status, bool isDark) {
  switch (status) {
    case SoilStatus.low:
      return isDark
          ? const _StatusConfig(bg: Color(0xFF1e293b), border: Color(0xFF3b82f6), text: Color(0xFF93c5fd))
          : const _StatusConfig(bg: Color(0xFFeff6ff), border: Color(0xFF93c5fd), text: Color(0xFF1d4ed8));
    case SoilStatus.normal:
      return isDark
          ? const _StatusConfig(bg: Color(0xFF14201a), border: Color(0xFF22c55e), text: Color(0xFF86efac))
          : const _StatusConfig(bg: Color(0xFFf0fdf4), border: Color(0xFF86efac), text: Color(0xFF15803d));
    case SoilStatus.high:
      return isDark
          ? const _StatusConfig(bg: Color(0xFF271515), border: Color(0xFFef4444), text: Color(0xFFfca5a5))
          : const _StatusConfig(bg: Color(0xFFfef2f2), border: Color(0xFFfca5a5), text: Color(0xFFb91c1c));
  }
}
