import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';

const _green600 = Color(0xFF16a34a);

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
  const RecommendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final data = ble.sensorData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final headerBg = isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF9ca3af);
    final textNormal =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF6b7280);

    return Scaffold(
      appBar: AppBar(
        title: const Text('คำแนะนำการปรับปรุงดิน'),
        backgroundColor: headerBg,
        foregroundColor: isDark ? const Color(0xFF4ade80) : Colors.white,
        titleTextStyle: TextStyle(
            color: isDark ? const Color(0xFFf9fafb) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),
      body: data == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_off, size: 48, color: textMuted),
                  SizedBox(height: 12),
                  Text('ไม่มีข้อมูลเซ็นเซอร์\nกรุณาเชื่อมต่ออุปกรณ์ก่อน',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textNormal)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _sensorKeys
                  .map((key) => _RecommendCard(
                        sensorKey: key,
                        value: data[key],
                      ))
                  .toList(),
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
    final textLabel =
        isDark ? const Color(0xFFf3f4f6) : const Color(0xFF1f2937);
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final textValue =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textLabel)),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // Value row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: config.text),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit,
                        style: TextStyle(
                            fontSize: 14, color: config.text.withOpacity(0.7))),
                  ),
                ],
                const Spacer(),
                Text(
                  'เกณฑ์: ${threshold.low.toStringAsFixed(threshold.low == threshold.low.roundToDouble() ? 0 : 1)}'
                  ' – ${threshold.high.toStringAsFixed(threshold.high == threshold.high.roundToDouble() ? 0 : 1)}'
                  '${unit.isNotEmpty ? " $unit" : ""}',
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF6b7280)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: config.border),

          // Recommendation
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 16, color: Color(0xFF6b7280)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('คำแนะนำ',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: textMuted)),
                      const SizedBox(height: 2),
                      Text(recommendation,
                          style: TextStyle(
                              fontSize: 13, color: textValue, height: 1.5)),
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
          color: config.badge, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 13, color: config.text),
          const SizedBox(width: 4),
          Text(statusLabels[status]!,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
      return Icons.check_circle_outline;
    case SoilStatus.high:
      return Icons.arrow_upward;
  }
}

class _StatusConfig {
  final Color bg;
  final Color border;
  final Color text;
  final Color badge;
  const _StatusConfig(
      {required this.bg,
      required this.border,
      required this.text,
      required this.badge});
}

_StatusConfig _statusConfig(SoilStatus status, bool isDark) {
  switch (status) {
    case SoilStatus.low:
      return isDark
          ? _StatusConfig(
              bg: const Color(0xFF1e3a5f),
              border: const Color(0xFF2563eb),
              text: const Color(0xFF93c5fd),
              badge: const Color(0xFF1e3a5f))
          : _StatusConfig(
              bg: const Color(0xFFeff6ff),
              border: const Color(0xFFbfdbfe),
              text: const Color(0xFF1d4ed8),
              badge: const Color(0xFFdbeafe));
    case SoilStatus.normal:
      return isDark
          ? _StatusConfig(
              bg: const Color(0xFF14532d),
              border: const Color(0xFF16a34a),
              text: const Color(0xFF86efac),
              badge: const Color(0xFF14532d))
          : _StatusConfig(
              bg: const Color(0xFFf0fdf4),
              border: const Color(0xFFbbf7d0),
              text: const Color(0xFF15803d),
              badge: const Color(0xFFdcfce7));
    case SoilStatus.high:
      return isDark
          ? _StatusConfig(
              bg: const Color(0xFF7f1d1d),
              border: const Color(0xFFdc2626),
              text: const Color(0xFFfca5a5),
              badge: const Color(0xFF7f1d1d))
          : _StatusConfig(
              bg: const Color(0xFFfef2f2),
              border: const Color(0xFFfecaca),
              text: const Color(0xFFb91c1c),
              badge: const Color(0xFFfee2e2));
  }
}
