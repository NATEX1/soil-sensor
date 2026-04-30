import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/sensor_data.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapBottomSheet extends StatelessWidget {
  final List<MeasurementRecord> validPoints;
  final MeasurementRecord? selected;
  final MapController mapController;
  final Function(MeasurementRecord?) onSelect;
  final double maxHeight;
  final ValueNotifier<double> sheetFraction;

  const MapBottomSheet({
    super.key,
    required this.validPoints,
    required this.selected,
    required this.mapController,
    required this.onSelect,
    required this.maxHeight,
    required this.sheetFraction,
  });

  void _onDragUpdate(DragUpdateDetails d) {
    sheetFraction.value -= d.delta.dy / maxHeight;
    sheetFraction.value = sheetFraction.value.clamp(0.16, 0.80);
  }

  void _onDragEnd(DragEndDetails d) {
    final targets = [0.35, 0.80];
    double closest = targets.first;
    for (final t in targets) {
      if ((sheetFraction.value - t).abs() < (sheetFraction.value - closest).abs()) {
        closest = t;
      }
    }
    sheetFraction.value = closest;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 🎨 Custom Colors isolated for Map Bottom Sheet
    final sheetBgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final titleColor = isDark ? const Color(0xFFf3f4f6) : const Color(0xFF111827);
    final subColor = isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle + header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'จุดเก็บตัวอย่าง (${validPoints.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      if (selected != null)
                        TextButton(
                          onPressed: () => onSelect(null),
                          style: TextButton.styleFrom(
                            foregroundColor: subColor,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('ล้างการเลือก', style: TextStyle(fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // List
          Expanded(
            child: validPoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off, size: 40, color: subColor),
                        const SizedBox(height: 8),
                        Text('ยังไม่มีจุดเก็บตัวอย่างที่มีพิกัด GPS',
                            style: TextStyle(color: subColor)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: validPoints.length,
                    itemBuilder: (_, i) {
                      final m = validPoints[i];
                      final isSelected = selected?.id == m.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            onSelect(isSelected ? null : m);
                            mapController.move(LatLng(m.lat, m.lng), 15);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: sheetBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.mapSelectedBorder
                                    : subColor.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 18, color: context.colors.mapPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.pointName?.isNotEmpty == true
                                            ? m.pointName!
                                            : m.plantName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: titleColor,
                                        ),
                                      ),
                                      if (m.measuredAt != null)
                                        Text(
                                          '${m.measuredAt!.day.toString().padLeft(2, '0')}/${m.measuredAt!.month.toString().padLeft(2, '0')}/${m.measuredAt!.year.toString().substring(2)} ${m.measuredAt!.hour.toString().padLeft(2, '0')}:${m.measuredAt!.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: subColor,
                                          ),
                                        ),
                                      Text(
                                        '${m.lat.toStringAsFixed(4)}, ${m.lng.toStringAsFixed(4)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontSize: 11, color: subColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'pH ${m.ph.toStringAsFixed(1)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.phColor,
                                      ),
                                    ),
                                    Text(
                                      'ชื้น ${m.moisture.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
