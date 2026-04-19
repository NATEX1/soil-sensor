import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/sensor_data.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';

class SaveModal extends StatefulWidget {
  final SensorData? sensorData;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  const SaveModal(
      {super.key,
      required this.sensorData,
      required this.onClose,
      required this.onSaved});

  @override
  State<SaveModal> createState() => _SaveModalState();
}

class _SaveModalState extends State<SaveModal> {
  String? _selectedPlantId;
  SampleMethod _sampleMethod = SampleMethod.surface0_15;
  final _notesController = TextEditingController();
  final _pointNameController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _locating = false;
  String? _error;
  List<Map<String, dynamic>> _plants = [];


  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await DatabaseService.getPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
        if (_plants.isNotEmpty && _selectedPlantId == null) {
          _selectedPlantId = _plants.first['id'] as String;
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pointNameController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      // location unavailable
    } finally {
      setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (widget.sensorData == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await DatabaseService.saveMeasurement(
        plantId: _selectedPlantId ?? 'rice',
        sampleMethod: _sampleMethod,
        pointName: _pointNameController.text.isEmpty ? null : _pointNameController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        lat: _lat ?? 0,
        lng: _lng ?? 0,
        ph: widget.sensorData!.ph,
        nitrogen: widget.sensorData!.nitrogen,
        phosphorus: widget.sensorData!.phosphorus,
        potassium: widget.sensorData!.potassium,
        moisture: widget.sensorData!.moisture,
        temperature: widget.sensorData!.temperature,
        ec: widget.sensorData!.ec,
        salinity: widget.sensorData!.salinity,
      );
      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Widget _buildChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.colors.primaryBtn : context.colors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? context.colors.primaryBtn
                  : context.colors.borderColor.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : context.colors.textMuted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.colors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('บันทึกผลการวัด',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: context.colors.textNormal)),
                  IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(Icons.close, color: context.colors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: context.colors.errorBg,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: context.colors.errorText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(color: context.colors.errorText, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  Text('ชื่อจุดเก็บตัวอย่าง',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pointNameController,
                    style: TextStyle(fontSize: 14, color: context.colors.textNormal),
                    decoration: InputDecoration(
                      hintText: 'เช่น จุดทดสอบที่ 1',
                      hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: context.colors.cardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: context.colors.borderColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: context.colors.primaryBtn.withValues(alpha: 0.5))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('ชนิดพืช',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._plants.map((p) {
                        return _buildChip(
                          p['name'] as String,
                          _selectedPlantId == p['id'],
                          () => setState(() => _selectedPlantId = p['id'] as String),
                        );
                      }),
                      _buildChip(
                        '+ เพิ่มชนิดพืชอื่น',
                        false,
                        _showAddPlantDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('วิธีเก็บตัวอย่าง',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<SampleMethod>(
                      groupValue: _sampleMethod,
                      onChanged: (v) => setState(() => _sampleMethod = v!),
                      child: Column(
                        children: SampleMethod.values.map((sm) =>
                          RadioListTile<SampleMethod>(
                            value: sm,
                            title: Text(sampleMethodLabels[sm]!,
                                style: TextStyle(fontSize: 14, color: context.colors.textNormal)),
                            activeColor: context.colors.primaryBtn,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            dense: true,
                          ),
                        ).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('หมายเหตุ',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: context.colors.textNormal),
                    decoration: InputDecoration(
                      hintText: 'บันทึกเพิ่มเติม...',
                      hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: context.colors.cardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: context.colors.borderColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: context.colors.primaryBtn.withValues(alpha: 0.5))),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.borderColor.withValues(alpha: 0.5))),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: context.colors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _locating
                              ? Text('กำลังระบุตำแหน่ง...',
                                  style:
                                      TextStyle(fontSize: 13, color: context.colors.textMuted))
                              : Text(
                                  _lat != null
                                      ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                      : 'ไม่สามารถระบุตำแหน่งได้',
                                  style:
                                      TextStyle(fontSize: 13, color: context.colors.textNormal),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: context.colors.textNormal,
                              side: BorderSide(color: context.colors.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.colors.primaryBtn,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('บันทึก',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPlantDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        title: Text('เพิ่มชนิดพืชอื่น', style: TextStyle(color: context.colors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.colors.textNormal),
          decoration: InputDecoration(
            hintText: 'เช่น มะม่วง, ทุเรียน, etc.',
            hintStyle: TextStyle(color: context.colors.textMuted.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: context.colors.primaryBtn),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final id = await DatabaseService.addPlant(name);
      await _loadPlants();
      if (mounted) {
        setState(() {
          _selectedPlantId = id;
        });
      }
    }
  }
}
