import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';

const _chartKeys = ['ph', 'nitrogen', 'phosphorus', 'potassium', 'moisture', 'temperature', 'ec', 'salinity'];

const Map<String, Color> _keyColors = {
  'ph':          Color(0xFF16a34a),
  'nitrogen':    Color(0xFF2563eb),
  'phosphorus':  Color(0xFFd97706),
  'potassium':   Color(0xFF7c3aed),
  'moisture':    Color(0xFF0891b2),
  'temperature': Color(0xFFdc2626),
  'ec':          Color(0xFF059669),
  'salinity':    Color(0xFFdb2777),
};

class SoilChart extends StatefulWidget {
  final List<MeasurementRecord> measurements;
  const SoilChart({super.key, required this.measurements});

  @override
  State<SoilChart> createState() => _SoilChartState();
}

class _SoilChartState extends State<SoilChart> {
  String _selectedKey = 'ph';

  List<FlSpot> get _spots {
    final sorted = [...widget.measurements]
      ..sort((a, b) => (a.measuredAt ?? DateTime(0)).compareTo(b.measuredAt ?? DateTime(0)));
    return sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value[_selectedKey]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = _spots;
    final color = _keyColors[_selectedKey] ?? const Color(0xFF16a34a);
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final gridColor = isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6);
    final textLabel = isDark ? const Color(0xFFf3f4f6) : const Color(0xFF1f2937);
    final textMuted = isDark ? const Color(0xFF9ca3af) : const Color(0xFF9ca3af);
    final unselectedText = isDark ? const Color(0xFFf3f4f6) : Colors.black;
    final unselectedBg = isDark ? const Color(0xFF374151) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Key selector
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _chartKeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final key = _chartKeys[i];
              final selected = _selectedKey == key;
              final c = _keyColors[key] ?? const Color(0xFF16a34a);
              return GestureDetector(
                onTap: () => setState(() => _selectedKey = key),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? c : unselectedBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? c : borderColor),
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Text(
                      sensorLabels[key] ?? key,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.0,
                        color: selected ? Colors.white : unselectedText,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sensorLabels[_selectedKey] ?? _selectedKey, style: TextStyle(fontWeight: FontWeight.bold, color: textLabel)),
                  Text(thresholds[_selectedKey]?.unit ?? '', style: TextStyle(fontSize: 12, color: textMuted)),
                ],
              ),
              const SizedBox(height: 16),
              if (spots.length < 2)
                const SizedBox(
                  height: 160,
                  child: Center(child: Text('ข้อมูลไม่เพียงพอสำหรับแสดงกราฟ', style: TextStyle(color: Color(0xFF9ca3af)))),
                )
              else
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: TextStyle(fontSize: 9, color: textMuted)))),
                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: color, strokeWidth: 2, strokeColor: isDark ? const Color(0xFF1f2937) : Colors.white),
                          ),
                          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
