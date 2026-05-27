import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/measurements_provider.dart';
import '../models/sensor_data.dart';

import '../theme/app_colors.dart';
import '../widgets/map/map_bottom_sheet.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class PlotMarker {
  final PlotRecord plot;
  final double lat;
  final double lng;
  PlotMarker(this.plot, this.lat, this.lng);
}

class _MapScreenState extends State<MapScreen> {
  PlotMarker? _selected;
  final MapController _mapController = MapController();
  final ValueNotifier<double> _sheetFraction = ValueNotifier(0.35);

  @override
  void dispose() {
    _sheetFraction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<MeasurementsProvider, bool>((p) => p.loading);
    final allPlots = context.select<MeasurementsProvider, List<PlotRecord>>((p) => p.allPlots);
    
    // Create PlotMarkers (Centroid of each plot)
    final plotMarkers = <PlotMarker>[];
    for (var p in allPlots) {
      final validMeasurements = p.measurements.toList(); // เอาทุกจุด ไม่กรอง 0 ออก
      if (validMeasurements.isEmpty) continue;

      double sumLat = 0;
      double sumLng = 0;
      int validCount = 0;

      for (var m in validMeasurements) {
        if (m.lat != 0 || m.lng != 0) {
          sumLat += m.lat;
          sumLng += m.lng;
          validCount++;
        }
      }
      
      double avgLat = 13.7563; // Default to Bangkok if no GPS
      double avgLng = 100.5018;

      if (p.lat != null && p.lng != null && p.lat != 0 && p.lng != 0) {
        // Use explicitly saved plot coordinates
        avgLat = p.lat!;
        avgLng = p.lng!;
      } else if (validCount > 0) {
        // Fallback to average of measurements
        avgLat = sumLat / validCount;
        avgLng = sumLng / validCount;
      }
      
      plotMarkers.add(PlotMarker(
        p, 
        avgLat, 
        avgLng,
      ));
    }
    
    final topPadding = MediaQuery.of(context).padding.top;

    final initialCenter = plotMarkers.isNotEmpty
        ? LatLng(plotMarkers.first.lat, plotMarkers.first.lng)
        : const LatLng(13.7563, 100.5018);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผนที่',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textNormal,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text('แสดง ${plotMarkers.length} แปลง',
                        style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          if (isLoading)
            Expanded(
              child: Center(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: context.colors.mapPrimary),
                  const SizedBox(height: 12),
                  Text('กำลังโหลดข้อมูล...',
                      style: TextStyle(color: context.colors.textMuted)),
                ],
              )),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Map
                      Positioned.fill(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: plotMarkers.isNotEmpty ? 10 : 5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                            onTap: (_, __) => setState(() => _selected = null),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.soil_sensor',
                            ),
                            MarkerLayer(
                              markers: plotMarkers
                                  .map((pm) => Marker(
                                        point: LatLng(pm.lat, pm.lng),
                                        width: 48,
                                        height: 48,
                                        child: GestureDetector(
                                          onTap: () => setState(() =>
                                              _selected = _selected?.plot.id == pm.plot.id
                                                  ? null
                                                  : pm),
                                          child: Icon(
                                            Icons.location_on,
                                            color: _selected?.plot.id == pm.plot.id
                                                ? Colors.orange
                                                : context.colors.mapPrimary,
                                            size: 48,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      // Bottom sheet (Smooth dragging with ValueNotifier)
                      ValueListenableBuilder<double>(
                        valueListenable: _sheetFraction,
                        builder: (context, fraction, child) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: constraints.maxHeight * fraction,
                            child: MapBottomSheet(
                              plotMarkers: plotMarkers,
                              selected: _selected,
                              onSelect: (m) => setState(() => _selected = m),
                              mapController: _mapController,
                              maxHeight: constraints.maxHeight,
                              sheetFraction: _sheetFraction,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

