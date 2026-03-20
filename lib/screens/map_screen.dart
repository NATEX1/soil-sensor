import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/measurements_provider.dart';
import '../models/sensor_data.dart';

const _green600 = Color(0xFF16a34a);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MeasurementRecord? _selected;
  final MapController _mapController = MapController();
  double _sheetFraction = 0.35;
  static const double _minFraction = 0.16;
  static const double _maxFraction = 0.70;

  void _onDragUpdate(DragUpdateDetails d, double maxHeight) {
    setState(() {
      _sheetFraction -= d.delta.dy / maxHeight;
      _sheetFraction = _sheetFraction.clamp(_minFraction, _maxFraction);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    // Snap to nearest position
    final targets = [_minFraction, 0.35, 0.70];
    double closest = targets.first;
    for (final t in targets) {
      if ((_sheetFraction - t).abs() < (_sheetFraction - closest).abs())
        closest = t;
    }
    setState(() => _sheetFraction = closest);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MeasurementsProvider>();
    final validPoints =
        provider.measurements.where((m) => m.lat != 0 || m.lng != 0).toList();
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final headerBg = isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
    final headerSubtitle =
        isDark ? const Color(0xFF6b7280) : const Color(0xFFbbf7d0);
    final primaryColor =
        isDark ? const Color(0xFF15803d) : const Color(0xFF16a34a);
    final selectedColor = Colors.orange;
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF9ca3af);
    final textNormal =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6);
    final dividerColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6);
    final dragHandleColor =
        isDark ? const Color(0xFF6b7280) : const Color(0xFFd1d5db);
    final selectedBorder =
        isDark ? const Color(0xFF16a34a) : const Color(0xFF86efac);
    final phColor = isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);

    final initialCenter = validPoints.isNotEmpty
        ? LatLng(validPoints.first.lat, validPoints.first.lng)
        : const LatLng(13.7563, 100.5018);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: headerBg,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
            child: Row(
              children: [
                Icon(Icons.map,
                    color: isDark ? const Color(0xFF4ade80) : Colors.white,
                    size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แผนที่จุดเก็บตัวอย่าง',
                        style: TextStyle(
                            color:
                                isDark ? const Color(0xFFf9fafb) : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('${validPoints.length} จุด',
                        style: TextStyle(color: headerSubtitle, fontSize: 12)),
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
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 12),
                  Text('กำลังโหลดข้อมูล...',
                      style: TextStyle(color: textMuted)),
                ],
              )),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxH = constraints.maxHeight;
                  final sheetHeight = maxH * _sheetFraction;

                  return Stack(
                    children: [
                      // Map
                      Positioned.fill(
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: validPoints.isNotEmpty ? 10 : 5,
                            onTap: (_, __) => setState(() => _selected = null),
                          ),
                          children: [
                            if (isDark)
                              ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  -1,
                                  0,
                                  0,
                                  0,
                                  255,
                                  0,
                                  -1,
                                  0,
                                  0,
                                  255,
                                  0,
                                  0,
                                  -1,
                                  0,
                                  255,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.soil_sensor',
                                ),
                              )
                            else
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
                                                ? selectedColor
                                                : primaryColor,
                                            size: 40,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      // Bottom sheet
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: sheetHeight,
                        child: Builder(
                            builder: (context) => Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20)),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          offset: Offset(0, -2))
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Drag handle + header (ลากได้ทั้งพื้นที่)
                                      GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onVerticalDragUpdate: (d) =>
                                            _onDragUpdate(d, maxH),
                                        onVerticalDragEnd: _onDragEnd,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Drag handle
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              child: Center(
                                                child: Container(
                                                  width: 40,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: dragHandleColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Header
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      16, 0, 16, 12),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                      'จุดเก็บตัวอย่าง (${validPoints.length})',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isDark
                                                              ? const Color(
                                                                  0xFFf3f4f6)
                                                              : const Color(
                                                                  0xFF1f2937))),
                                                  if (_selected != null)
                                                    TextButton(
                                                      onPressed: () => setState(
                                                          () =>
                                                              _selected = null),
                                                      child: const Text(
                                                          'ล้างการเลือก'),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Divider(
                                                height: 1, color: dividerColor),
                                          ],
                                        ),
                                      ),
                                      // List
                                      Expanded(
                                        child: validPoints.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.location_off,
                                                        size: 40,
                                                        color: textMuted),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                        'ยังไม่มีจุดเก็บตัวอย่างที่มีพิกัด GPS',
                                                        style: TextStyle(
                                                            color: textMuted)),
                                                  ],
                                                ),
                                              )
                                            : ListView.builder(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        12, 8, 12, 12),
                                                itemCount: validPoints.length,
                                                itemBuilder: (_, i) {
                                                  final m = validPoints[i];
                                                  final isSelected =
                                                      _selected?.id == m.id;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 8),
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(() =>
                                                            _selected =
                                                                isSelected
                                                                    ? null
                                                                    : m);
                                                        _mapController.move(
                                                            LatLng(
                                                                m.lat, m.lng),
                                                            15);
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: cardBg,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                              color: isSelected
                                                                  ? selectedBorder
                                                                  : borderColor),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                                Icons
                                                                    .location_on,
                                                                size: 18,
                                                                color:
                                                                    primaryColor),
                                                            const SizedBox(
                                                                width: 8),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                      plantTypeLabels[m
                                                                              .plantType] ??
                                                                          '',
                                                                      style: TextStyle(
                                                                          fontWeight: FontWeight
                                                                              .w600,
                                                                          fontSize:
                                                                              14,
                                                                          color: isDark
                                                                              ? const Color(0xFFf3f4f6)
                                                                              : const Color(0xFF1f2937))),
                                                                  if (m.measuredAt !=
                                                                      null)
                                                                    Text(
                                                                      '${m.measuredAt!.day.toString().padLeft(2, '0')}/${m.measuredAt!.month.toString().padLeft(2, '0')}/${m.measuredAt!.year.toString().substring(2)} ${m.measuredAt!.hour.toString().padLeft(2, '0')}:${m.measuredAt!.minute.toString().padLeft(2, '0')}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              textMuted),
                                                                    ),
                                                                  Text(
                                                                      '${m.lat.toStringAsFixed(5)}, ${m.lng.toStringAsFixed(5)}',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              11,
                                                                          color:
                                                                              textMuted)),
                                                                ],
                                                              ),
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Text(
                                                                    'pH ${m.ph.toStringAsFixed(1)}',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        color:
                                                                            phColor)),
                                                                Text(
                                                                    'ชื้น ${m.moisture.toStringAsFixed(0)}%',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            11,
                                                                        color:
                                                                            textMuted)),
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
                                )),
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
