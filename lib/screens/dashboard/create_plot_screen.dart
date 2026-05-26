import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../theme/app_colors.dart';
import '../../providers/plot_provider.dart';

class CreatePlotScreen extends StatefulWidget {
  final LatLng initialLocation;

  const CreatePlotScreen({
    super.key,
    this.initialLocation = const LatLng(13.7563, 100.5018), // Default to Bangkok
  });

  @override
  State<CreatePlotScreen> createState() => _CreatePlotScreenState();
}

class _CreatePlotScreenState extends State<CreatePlotScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  late LatLng _currentCenter;
  LatLng? _userLocation;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation;
    _nameController.text = 'แปลง ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      final newLoc = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentCenter = newLoc;
        _userLocation = newLoc;
      });
      _mapController.move(newLoc, 15);
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _showEditNameModal() async {
    final tempController = TextEditingController(text: _nameController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ตั้งชื่อแปลง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: tempController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'เช่น แปลงมันสำปะหลัง',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, tempController.text.trim()),
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _nameController.text = result;
      });
    }
  }

  Future<void> _savePlot() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุชื่อแปลง')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final plotProvider = context.read<PlotProvider>();
      await plotProvider.startNewPlot(
        name,
        lat: _currentCenter.latitude,
        lng: _currentCenter.longitude,
      );
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Map Layer (Full Screen)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentCenter = position.center!;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.soil_sensor',
              ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // 2. Center Pin Overlay (Static on screen)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Offset to point to exact center
              child: Icon(
                Icons.location_on,
                size: 48,
                color: Colors.red,
              ),
            ),
          ),
          
          // 3. Top Floating App Bar & Search
          Positioned(
            top: topPadding + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.colors.textNormal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Plot Name Display (Clickable)
                Expanded(
                  child: GestureDetector(
                    onTap: _showEditNameModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _nameController.text,
                              style: TextStyle(fontWeight: FontWeight.w700, color: context.colors.textNormal, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.edit, size: 20, color: context.colors.primaryBtn),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 4. Current Location FAB
          Positioned(
            right: 16,
            bottom: 180, // Above the bottom panel
            child: FloatingActionButton(
              heroTag: 'current_loc_btn',
              onPressed: _getCurrentLocation,
              backgroundColor: context.colors.cardBg,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: _isGettingLocation
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.colors.primaryBtn, strokeWidth: 2))
                  : Icon(Icons.my_location, color: context.colors.primaryBtn),
            ),
          ),
          
          // 5. Bottom Panel
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.primaryBtn.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.location_on_outlined, size: 18, color: context.colors.primaryBtn),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('พิกัดที่เลือก', style: TextStyle(fontSize: 12, color: context.colors.textMuted, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  '${_currentCenter.latitude.toStringAsFixed(5)}, ${_currentCenter.longitude.toStringAsFixed(5)}',
                                  style: TextStyle(color: context.colors.textNormal, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _savePlot,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.colors.primaryBtn,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('ยืนยันสร้างแปลง', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
