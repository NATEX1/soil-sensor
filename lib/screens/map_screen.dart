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

class _MapScreenState extends State<MapScreen> {
  MeasurementRecord? _selected;
  final MapController _mapController = MapController();
  final ValueNotifier<double> _sheetFraction = ValueNotifier(0.35);

  @override
  void dispose() {
    _sheetFraction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeasurementsProvider>();
    final validPoints =
        provider.mapMeasurements.where((m) => m.lat != 0 || m.lng != 0).toList();
    final topPadding = MediaQuery.of(context).padding.top;

    final initialCenter = validPoints.isNotEmpty
        ? LatLng(validPoints.first.lat, validPoints.first.lng)
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
                    Text('ตำแหน่งวัด (มีพิกัด ${validPoints.length} จุด)',
                        style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          if (provider.loading)
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
                            initialZoom: validPoints.isNotEmpty ? 10 : 5,
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
                              markers: validPoints
                                  .map((m) => Marker(
                                        point: LatLng(m.lat, m.lng),
                                        width: 40,
                                        height: 40,
                                        child: GestureDetector(
                                          onTap: () => setState(() =>
                                              _selected = _selected?.id == m.id
                                                  ? null
                                                  : m),
                                          child: Icon(
                                            Icons.location_on,
                                            color: _selected?.id == m.id
                                                ? Colors.orange
                                                : context.colors.mapPrimary,
                                            size: 40,
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
                              validPoints: validPoints,
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
