import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';
import '../services/api_service.dart';
import '../providers/measurements_provider.dart';
import '../providers/plot_provider.dart';
import '../theme/app_colors.dart';

class PlotMeasurementsScreen extends StatefulWidget {
  final PlotRecord plot;

  const PlotMeasurementsScreen({super.key, required this.plot});

  @override
  State<PlotMeasurementsScreen> createState() => _PlotMeasurementsScreenState();
}

class _PlotMeasurementsScreenState extends State<PlotMeasurementsScreen> {
  late List<MeasurementRecord> _measurements;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _measurements = List.from(widget.plot.measurements);
  }

  Future<void> _deleteMeasurement(MeasurementRecord record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ลบข้อมูลการวัด',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textNormal)),
        content: Text('คุณต้องการลบข้อมูลการวัดนี้ใช่หรือไม่?',
            style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ลบ', style: TextStyle(color: Colors.red.shade500, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (record.id == null) return;

    setState(() => _isDeleting = true);
    try {
      await ApiService.deleteMeasurement(record.id!);
      
      // Update local state
      setState(() {
        _measurements.removeWhere((m) => m.id == record.id);
        // Also mutate the parent's list so when popped, it reflects changes
        widget.plot.measurements.removeWhere((m) => m.id == record.id);
      });

      if (mounted) {
        context.read<MeasurementsProvider>().fetch();
        context.read<PlotProvider>().loadAvailablePlots();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ลบข้อมูลการวัดสำเร็จ'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถลบได้: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: topPadding + 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.arrow_back_ios_new, size: 20, color: context.colors.textNormal),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ข้อมูลการวัด',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textNormal,
                              letterSpacing: -0.5)),
                      Text('แปลง: ${widget.plot.name}',
                          style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _measurements.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off, size: 48, color: context.colors.textMuted),
                        const SizedBox(height: 12),
                        Text('ไม่มีข้อมูลการวัดในแปลงนี้',
                            style: TextStyle(color: context.colors.textMuted)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _measurements.length,
                        itemBuilder: (context, index) {
                          final record = _measurements[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MeasurementCard(
                              record: record,
                              onDelete: () => _deleteMeasurement(record),
                            ),
                          );
                        },
                      ),
                      if (_isDeleting)
                        Container(
                          color: Colors.black.withValues(alpha: 0.2),
                          child: Center(
                            child: CircularProgressIndicator(color: context.colors.primaryBtn),
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

class _MeasurementCard extends StatelessWidget {
  final MeasurementRecord record;
  final VoidCallback onDelete;
  
  const _MeasurementCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = record.measuredAt;
    final dateStr = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '-';

    final metrics = [
      ('pH', record.ph.toStringAsFixed(1), getSoilStatus('ph', record.ph)),
      ('N', record.nitrogen.toStringAsFixed(0), getSoilStatus('nitrogen', record.nitrogen)),
      ('P', record.phosphorus.toStringAsFixed(0), getSoilStatus('phosphorus', record.phosphorus)),
      ('K', record.potassium.toStringAsFixed(0), getSoilStatus('potassium', record.potassium)),
      ('ชื้น', '${record.moisture.toStringAsFixed(0)}%', getSoilStatus('moisture', record.moisture)),
      ('EC', record.ec.toStringAsFixed(1), getSoilStatus('ec', record.ec)),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.pointName ?? 'จุดที่ ${record.id?.substring(0, 6) ?? ""}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textNormal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(dateStr, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
          if (record.lat != 0 || record.lng != 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: context.colors.textMuted),
                const SizedBox(width: 4),
                Text(
                  '${record.lat.toStringAsFixed(6)}, ${record.lng.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 11, color: context.colors.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: metrics.map((m) {
              final (label, val, status) = m;
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$label ', style: TextStyle(fontSize: 11, color: text.withValues(alpha: 0.7))),
                    Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
