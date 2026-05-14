import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sensor_data.dart';
import '../../models/calculations.dart';
import '../../theme/app_colors.dart';

class TrendChart extends StatelessWidget {
  final List<MeasurementRecord> measurements;
  final String sensorKey;
  final String? currentMeasurementId;

  const TrendChart({
    super.key,
    required this.measurements,
    required this.sensorKey,
    this.currentMeasurementId,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.length < 2) return const SizedBox.shrink();

    final threshold = thresholds[sensorKey]!;
    final label = sensorLabels[sensorKey] ?? sensorKey;
    final unit = threshold.unit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build data points
    final spots = <FlSpot>[];
    final dates = <int, DateTime>{};
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < measurements.length; i++) {
      final m = measurements[i];
      final value = m[sensorKey];
      spots.add(FlSpot(i.toDouble(), value));
      if (m.measuredAt != null) dates[i] = m.measuredAt!;
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Include threshold range in Y axis
    if (threshold.low < minY) minY = threshold.low;
    if (threshold.high > maxY) maxY = threshold.high;

    // Add padding to Y range
    final yRange = maxY - minY;
    final padding = yRange * 0.15;
    minY = minY - padding;
    maxY = maxY + padding;
    if (minY < 0 && threshold.low >= 0) minY = 0;

    // Find index of current measurement
    int? currentIndex;
    if (currentMeasurementId != null) {
      for (int i = 0; i < measurements.length; i++) {
        if (measurements[i].id == currentMeasurementId) {
          currentIndex = i;
          break;
        }
      }
    }

    final colors = _sensorColors(sensorKey, isDark);
    final primaryColor = colors.$1;
    final thresholdColor = colors.$2;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colors.textNormal,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '($unit)',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              minX: 0,
              maxX: (measurements.length - 1).toDouble(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yRange > 0 ? yRange / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: gridColor,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.min || value == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: _calcBottomInterval(measurements.length),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= measurements.length) {
                        return const SizedBox.shrink();
                      }
                      final date = dates[idx];
                      if (date == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: TextStyle(
                            fontSize: 9,
                            color: context.colors.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: threshold.low.clamp(minY, maxY),
                    y2: threshold.high.clamp(minY, maxY),
                    color: thresholdColor,
                  ),
                ],
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => isDark
                      ? const Color(0xFF374151)
                      : Colors.white,
                  tooltipRoundedRadius: 10,
                  tooltipBorder: BorderSide(
                    color: context.colors.borderColor,
                    width: 1,
                  ),
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final idx = spot.x.toInt();
                      final date = dates[idx];
                      final dateStr = date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : '';
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}${unit.isNotEmpty ? " $unit" : ""}\n',
                        TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                        children: [
                          TextSpan(
                            text: dateStr,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: primaryColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final isCurrentPoint = currentIndex != null && index == currentIndex;
                      if (isCurrentPoint) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: primaryColor,
                          strokeWidth: 3,
                          strokeColor: isDark
                              ? const Color(0xFF1f2937)
                              : Colors.white,
                        );
                      }
                      return FlDotCirclePainter(
                        radius: 3,
                        color: primaryColor,
                        strokeWidth: 2,
                        strokeColor: isDark
                            ? const Color(0xFF1f2937)
                            : Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withValues(alpha: 0.2),
                        primaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          ),
        ),
        // Threshold legend
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: thresholdColor,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'เกณฑ์ปกติ: ${threshold.low.toStringAsFixed(threshold.low == threshold.low.roundToDouble() ? 0 : 1)}'
              ' – ${threshold.high.toStringAsFixed(threshold.high == threshold.high.roundToDouble() ? 0 : 1)}'
              '${unit.isNotEmpty ? " $unit" : ""}',
              style: TextStyle(
                fontSize: 10,
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calcBottomInterval(int count) {
    if (count <= 5) return 1;
    if (count <= 10) return 2;
    if (count <= 20) return 4;
    return (count / 5).ceilToDouble();
  }

  /// Returns (lineColor, thresholdBandColor) for each sensor key.
  static (Color, Color) _sensorColors(String key, bool isDark) {
    switch (key) {
      case 'ph':
        final c = isDark ? const Color(0xFFa78bfa) : const Color(0xFF7c3aed);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'nitrogen':
        final c = isDark ? const Color(0xFF4ade80) : const Color(0xFF16a34a);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'phosphorus':
        final c = isDark ? const Color(0xFFfbbf24) : const Color(0xFFd97706);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'potassium':
        final c = isDark ? const Color(0xFFfb7185) : const Color(0xFFe11d48);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'moisture':
        final c = isDark ? const Color(0xFF38bdf8) : const Color(0xFF0284c7);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'temperature':
        final c = isDark ? const Color(0xFFfb923c) : const Color(0xFFea580c);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'ec':
        final c = isDark ? const Color(0xFF818cf8) : const Color(0xFF4f46e5);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      case 'salinity':
        final c = isDark ? const Color(0xFF2dd4bf) : const Color(0xFF0d9488);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
      default:
        final c = isDark ? const Color(0xFF4ade80) : const Color(0xFF16a34a);
        return (c, c.withValues(alpha: isDark ? 0.08 : 0.1));
    }
  }
}
