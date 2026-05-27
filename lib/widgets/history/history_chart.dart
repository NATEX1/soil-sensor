import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sensor_data.dart';
import '../../models/calculations.dart';
import '../../theme/app_colors.dart';

/// A chart widget that displays historical trends of soil sensor values
/// across all plots over time. Each data point represents a plot's average value.
class HistoryChart extends StatefulWidget {
  final List<PlotRecord> plots;
  const HistoryChart({super.key, required this.plots});

  @override
  State<HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  String _selectedKey = 'ph';
  bool _isExpanded = true;

  static const _sensorOptions = [
    ('ph', 'pH'),
    ('nitrogen', 'N'),
    ('phosphorus', 'P'),
    ('potassium', 'K'),
    ('moisture', 'ชื้น'),
    ('temperature', 'อุณหภูมิ'),
    ('ec', 'EC'),
    ('salinity', 'เค็ม'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort plots by date ascending for the chart
    final sorted = List<PlotRecord>.from(widget.plots)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Need at least 2 points for a meaningful chart
    if (sorted.length < 2) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header - tap to expand/collapse
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Icon(Icons.show_chart_rounded, size: 20, color: context.colors.primaryBtn),
                  const SizedBox(width: 10),
                  Text(
                    'แนวโน้มค่าดิน',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textNormal,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showInfoDialog(context),
                    icon: Icon(Icons.info_outline_rounded, size: 20, color: context.colors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chart body
          AnimatedCrossFade(
            firstChild: _buildChartBody(context, sorted, isDark),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBody(BuildContext context, List<PlotRecord> sorted, bool isDark) {
    final threshold = thresholds[_selectedKey]!;
    final unit = threshold.unit;
    final colors = _sensorColors(_selectedKey, isDark);
    final primaryColor = colors.$1;
    final thresholdColor = colors.$2;

    // Build data points
    final spots = <FlSpot>[];
    final dateMap = <int, DateTime>{};
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < sorted.length; i++) {
      final value = sorted[i][_selectedKey];
      spots.add(FlSpot(i.toDouble(), value));
      dateMap[i] = sorted[i].createdAt;
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Include threshold range
    if (threshold.low < minY) minY = threshold.low;
    if (threshold.high > maxY) maxY = threshold.high;

    final yRange = maxY - minY;
    final padding = yRange * 0.15;
    minY = minY - padding;
    maxY = maxY + padding;
    if (minY < 0 && threshold.low >= 0) minY = 0;

    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensor selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _sensorOptions.map((opt) {
                final isSelected = opt.$1 == _selectedKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedKey = opt.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _sensorColors(opt.$1, isDark).$1.withValues(alpha: 0.15)
                            : context.colors.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? _sensorColors(opt.$1, isDark).$1
                              : context.colors.borderColor.withValues(alpha: 0.5),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        opt.$2,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? _sensorColors(opt.$1, isDark).$1
                              : context.colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // The chart
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: 180,
              width: sorted.length <= 5 
                  ? MediaQuery.of(context).size.width - 32 
                  : (sorted.length * 70.0).toDouble(),
              child: Padding(
                padding: const EdgeInsets.only(right: 16, left: 8),
                child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                minX: 0,
                maxX: (sorted.length - 1).toDouble(),
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
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        unit.isNotEmpty ? unit : '',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.colors.textMuted),
                      ),
                    ),
                    axisNameSize: unit.isNotEmpty ? 20 : 0,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                            style: TextStyle(fontSize: 10, color: context.colors.textMuted),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 54,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                        final plot = sorted[idx];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 12,
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Text(
                              plot.name,
                              style: TextStyle(fontSize: 9, color: context.colors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                        final date = dateMap[idx]!;
                        final plot = sorted[idx];
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}${unit.isNotEmpty ? " $unit" : ""}\n',
                          TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                          children: [
                            TextSpan(
                              text: '${plot.name}\n',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.colors.textNormal,
                              ),
                            ),
                            TextSpan(
                              text: '${plot.measurementCount} จุดวัด | ${date.day}/${date.month}/${date.year}',
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
                        return FlDotCirclePainter(
                          radius: 4,
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
          ),
          ),

          // Legend
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: thresholdColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'เกณฑ์ปกติ: ${threshold.low.toStringAsFixed(threshold.low == threshold.low.roundToDouble() ? 0 : 1)}'
                ' – ${threshold.high.toStringAsFixed(threshold.high == threshold.high.roundToDouble() ? 0 : 1)}'
                '${unit.isNotEmpty ? " $unit" : ""}',
                style: TextStyle(fontSize: 10, color: context.colors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: context.colors.primaryBtn),
            const SizedBox(width: 10),
            Text('วิธีอ่านกราฟ', style: TextStyle(color: context.colors.textNormal)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoItem(context, Icons.lens, 'จุดบนกราฟ', 'แสดง "ค่าเฉลี่ย" จากทุกจุดที่วัดในแปลงนั้นๆ'),
            const SizedBox(height: 12),
            _infoItem(context, Icons.format_color_fill_rounded, 'แถบสีพื้นหลัง', 'แสดงช่วง "เกณฑ์ปกติ" ของพืชตระกูลมัน'),
            const SizedBox(height: 12),
            _infoItem(context, Icons.touch_app_rounded, 'การโต้ตอบ', 'แตะที่จุดเพื่อดูรายละเอียดและวันที่วัด'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง', style: TextStyle(color: context.colors.primaryBtn, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: context.colors.primaryBtn.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.colors.textNormal)),
              Text(desc, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  double _calcInterval(int count) {
    if (count <= 5) return 1;
    if (count <= 10) return 2;
    if (count <= 20) return 4;
    return (count / 5).ceilToDouble();
  }

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
