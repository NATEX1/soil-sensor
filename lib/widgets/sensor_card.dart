import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';

class SensorCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final String thresholdKey;

  const SensorCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.thresholdKey,
  });

  @override
  Widget build(BuildContext context) {
    final status = getSoilStatus(thresholdKey, value);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = _statusConfig(status, isDark);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6b7280), fontWeight: FontWeight.w500)),
              _StatusIcon(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            unit.isEmpty ? value.toStringAsFixed(1) : '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: config.text),
          ),
          const SizedBox(height: 2),
          Text(statusLabels[status]!, style: TextStyle(fontSize: 11, color: config.text)),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final SoilStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SoilStatus.low:
        return const Icon(Icons.arrow_downward, size: 16, color: Color(0xFF2563eb));
      case SoilStatus.normal:
        return const Icon(Icons.check_circle, size: 16, color: Color(0xFF16a34a));
      case SoilStatus.high:
        return const Icon(Icons.arrow_upward, size: 16, color: Color(0xFFdc2626));
    }
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
          ? _StatusConfig(bg: const Color(0xFF1e3a5f), border: const Color(0xFF2563eb), text: const Color(0xFF93c5fd))
          : _StatusConfig(bg: const Color(0xFFeff6ff), border: const Color(0xFFbfdbfe), text: const Color(0xFF1d4ed8));
    case SoilStatus.normal:
      return isDark
          ? _StatusConfig(bg: const Color(0xFF14532d), border: const Color(0xFF16a34a), text: const Color(0xFF86efac))
          : _StatusConfig(bg: const Color(0xFFf0fdf4), border: const Color(0xFFbbf7d0), text: const Color(0xFF15803d));
    case SoilStatus.high:
      return isDark
          ? _StatusConfig(bg: const Color(0xFF7f1d1d), border: const Color(0xFFdc2626), text: const Color(0xFFfca5a5))
          : _StatusConfig(bg: const Color(0xFFfef2f2), border: const Color(0xFFfecaca), text: const Color(0xFFb91c1c));
  }
}
