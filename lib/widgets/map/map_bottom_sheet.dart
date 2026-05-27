import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../screens/map_screen.dart'; // import PlotMarker

class MapBottomSheet extends StatelessWidget {
  final List<PlotMarker> plotMarkers;
  final PlotMarker? selected;
  final MapController mapController;
  final Function(PlotMarker?) onSelect;
  final double maxHeight;
  final ValueNotifier<double> sheetFraction;

  const MapBottomSheet({
    super.key,
    required this.plotMarkers,
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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.cardBg,
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
                        color: context.colors.textMuted.withValues(alpha: 0.3),
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
                        'ข้อมูลแปลง (${plotMarkers.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textNormal,
                        ),
                      ),
                      if (selected != null)
                        TextButton(
                          onPressed: () => onSelect(null),
                          style: TextButton.styleFrom(
                            foregroundColor: context.colors.textMuted,
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
            child: plotMarkers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.landscape_rounded, size: 40, color: context.colors.textMuted),
                        const SizedBox(height: 8),
                        Text('ไม่มีแปลงที่มีพิกัด GPS',
                            style: TextStyle(color: context.colors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: plotMarkers.length,
                    itemBuilder: (_, index) {
                      final pm = plotMarkers[index];
                      final plot = pm.plot;
                      final isSelected = selected?.plot.id == pm.plot.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            onSelect(isSelected ? null : pm);
                            mapController.move(LatLng(pm.lat, pm.lng), 15);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? context.colors.primaryBtn.withValues(alpha: 0.05) : context.colors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? context.colors.mapSelectedBorder
                                    : context.colors.textMuted.withValues(alpha: 0.15),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Plot Info
                                Row(
                                  children: [
                                    Icon(Icons.landscape, size: 20, color: context.colors.primaryBtn),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        plot.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isSelected ? context.colors.primaryBtn : context.colors.textNormal,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: context.colors.primaryBtn.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${plot.measurementCount} จุด',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.primaryBtn,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Plot Averages
                                Row(
                                  children: [
                                    _buildAvergeChip(context, 'pH', plot.ph.toStringAsFixed(1), context.colors.phColor),
                                    const SizedBox(width: 8),
                                    _buildAvergeChip(context, 'ความชื้น', '${plot.moisture.toStringAsFixed(0)}%', Colors.blue),
                                    const SizedBox(width: 8),
                                    _buildAvergeChip(context, 'N', plot.nitrogen.toStringAsFixed(0), context.colors.textNormal),
                                    const SizedBox(width: 8),
                                    _buildAvergeChip(context, 'P', plot.phosphorus.toStringAsFixed(0), context.colors.textNormal),
                                    const SizedBox(width: 8),
                                    _buildAvergeChip(context, 'K', plot.potassium.toStringAsFixed(0), context.colors.textNormal),
                                  ],
                                ),
                                
                                // Coordinates
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: context.colors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'พิกัดกึ่งกลาง: ${pm.lat.toStringAsFixed(4)}, ${pm.lng.toStringAsFixed(4)}',
                                      style: TextStyle(fontSize: 12, color: context.colors.textMuted),
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

  Widget _buildAvergeChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
