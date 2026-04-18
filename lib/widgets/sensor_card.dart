import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';
import '../theme/app_colors.dart';

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
    final valueText = unit.isEmpty
        ? value.toStringAsFixed(1)
        : '${value.toStringAsFixed(1)} $unit';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textMuted,
                        fontWeight: FontWeight.w500)),
              ),
              _StatusDot(status: status),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            ),
            child: Text(
              valueText,
              key: ValueKey(valueText),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: config.text,
                  letterSpacing: -0.3),
            ),
          ),
          const Spacer(),
          Text(statusLabels[status]!,
              style: TextStyle(
                  fontSize: 10,
                  color: config.text.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final SoilStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SoilStatus.low => (const Color(0xFF3b82f6), Icons.arrow_downward),
      SoilStatus.normal => (const Color(0xFF16a34a), Icons.check_circle),
      SoilStatus.high => (const Color(0xFFef4444), Icons.arrow_upward),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: color),
    );
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
          ? const _StatusConfig(bg: Color(0xFF1e293b), border: Color(0xFF334155), text: Color(0xFF93c5fd))
          : const _StatusConfig(bg: Color(0xFFf0f7ff), border: Color(0xFFdbeafe), text: Color(0xFF1d4ed8));
    case SoilStatus.normal:
      return isDark
          ? const _StatusConfig(bg: Color(0xFF14201a), border: Color(0xFF1a3a2a), text: Color(0xFF86efac))
          : const _StatusConfig(bg: Color(0xFFf0fdf4), border: Color(0xFFdcfce7), text: Color(0xFF15803d));
    case SoilStatus.high:
      return isDark
          ? const _StatusConfig(bg: Color(0xFF271515), border: Color(0xFF3f1a1a), text: Color(0xFFfca5a5))
          : const _StatusConfig(bg: Color(0xFFfef7f7), border: Color(0xFFfee2e2), text: Color(0xFFb91c1c));
  }
}
