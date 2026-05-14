import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/sensor_data.dart';
import '../../models/calculations.dart';

class HistoryListView extends StatelessWidget {
  final List<PlotRecord> plots;
  final void Function(String plotId)? onDelete;
  const HistoryListView({super.key, required this.plots, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    if (isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 180,
        ),
        itemCount: plots.length,
        itemBuilder: (context, index) => _buildCard(context, plots[index]),
      );
    }

    return Column(
      children: plots.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildCard(context, p),
      )).toList(),
    );
  }

  Widget _buildCard(BuildContext context, PlotRecord plot) {
    return _HistoryCard(plot: plot);
  }
}

class _HistoryCard extends StatelessWidget {
  final PlotRecord plot;
  const _HistoryCard({required this.plot});

  @override
  Widget build(BuildContext context) {
    final date = plot.createdAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    // Count abnormal values
    final abnormalKeys = <String>[];
    for (final key in ['ph', 'nitrogen', 'phosphorus', 'potassium', 'moisture', 'temperature', 'ec', 'salinity']) {
      final status = getSoilStatus(key, plot[key]);
      if (status != SoilStatus.normal) {
        abnormalKeys.add(key);
      }
    }

    return GestureDetector(
      onTap: () => context.push('/recommend', extra: plot),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: plot name
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plot.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textNormal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: context.colors.textMuted),
              ],
            ),
            const SizedBox(height: 4),

            // Date and measurement count
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: context.colors.textMuted),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
                const SizedBox(width: 12),
                Icon(Icons.format_list_numbered, size: 13, color: context.colors.primaryBtn),
                const SizedBox(width: 4),
                Text('${plot.measurementCount} จุด',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.primaryBtn)),
              ],
            ),
            const SizedBox(height: 12),

            // Sensor summary chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SensorChip(label: 'pH', value: plot.ph.toStringAsFixed(1), status: getSoilStatus('ph', plot.ph)),
                _SensorChip(label: 'N', value: plot.nitrogen.round().toString(), status: getSoilStatus('nitrogen', plot.nitrogen)),
                _SensorChip(label: 'P', value: plot.phosphorus.round().toString(), status: getSoilStatus('phosphorus', plot.phosphorus)),
                _SensorChip(label: 'K', value: plot.potassium.round().toString(), status: getSoilStatus('potassium', plot.potassium)),
                _SensorChip(label: 'ชื้น', value: '${plot.moisture.round()}%', status: getSoilStatus('moisture', plot.moisture)),
                _SensorChip(label: 'EC', value: plot.ec.toStringAsFixed(1), status: getSoilStatus('ec', plot.ec)),
              ],
            ),

            // Warning row if abnormal values exist
            if (abnormalKeys.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.warningBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.warningBorder.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: context.colors.warningOrange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'มี ${abnormalKeys.length} ค่าเฉลี่ยที่ผิดปกติ — กดเพื่อดูคำแนะนำ',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.colors.warningOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  final String label;
  final String value;
  final SoilStatus status;
  const _SensorChip({required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color text;
    switch (status) {
      case SoilStatus.low:
        bg = isDark ? const Color(0xFF1e3a5f) : const Color(0xFFdbeafe);
        text = isDark ? const Color(0xFF93c5fd) : const Color(0xFF1d4ed8);
        break;
      case SoilStatus.high:
        bg = isDark ? const Color(0xFF450a0a) : const Color(0xFFfee2e2);
        text = isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);
        break;
      case SoilStatus.normal:
        bg = isDark ? const Color(0xFF052e16) : const Color(0xFFdcfce7);
        text = isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: TextStyle(fontSize: 11, color: text.withValues(alpha: 0.7))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
        ],
      ),
    );
  }
}
