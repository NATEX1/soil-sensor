import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/sensor_data.dart';
import '../services/database_service.dart';

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
  PlantType _plantType = PlantType.rice;
  SampleMethod _sampleMethod = SampleMethod.surface0_15;
  final _notesController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _notesController.dispose();
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
        plantType: _plantType,
        sampleMethod: _sampleMethod,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final sheetBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final dragHandleColor =
        isDark ? const Color(0xFF6b7280) : Colors.grey[300]!;
    final textTitle =
        isDark ? const Color(0xFFf3f4f6) : const Color(0xFF1f2937);
    final textLabel =
        isDark ? const Color(0xFFd1d5db) : const Color(0xFF6b7280);
    final textValue =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);
    final primaryBtn =
        isDark ? const Color(0xFF16a34a) : const Color(0xFF16a34a);
    final cardBg = isDark ? const Color(0xFF111827) : const Color(0xFFf9fafb);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final errorBg = isDark ? const Color(0xFF450a0a) : const Color(0xFFfef2f2);
    final errorBorder =
        isDark ? const Color(0xFF991b1b) : const Color(0xFFfecaca);
    final errorText =
        isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);
    final inputBorder =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final chipUnselectedBg = isDark ? const Color(0xFF374151) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: dragHandleColor,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('บันทึกผลการวัด',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textTitle)),
                  IconButton(
                      onPressed: widget.onClose, icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: errorBorder)),
                      child: Text(_error!,
                          style: TextStyle(color: errorText, fontSize: 13)),
                    ),
                  Text('ชนิดพืช',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLabel)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PlantType.values.map((pt) {
                      final selected = _plantType == pt;
                      return GestureDetector(
                        onTap: () => setState(() => _plantType = pt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? primaryBtn : chipUnselectedBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: selected ? primaryBtn : borderColor),
                          ),
                          child: Text(plantTypeLabels[pt]!,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? Colors.white : textValue)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('วิธีเก็บตัวอย่าง',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLabel)),
                  const SizedBox(height: 8),
                  ...SampleMethod.values.map((sm) =>
                      RadioListTile<SampleMethod>(
                        value: sm,
                        groupValue: _sampleMethod,
                        onChanged: (v) => setState(() => _sampleMethod = v!),
                        title: Text(sampleMethodLabels[sm]!,
                            style: TextStyle(fontSize: 14, color: textValue)),
                        activeColor: primaryBtn,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      )),
                  const SizedBox(height: 16),
                  Text('หมายเหตุ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textLabel)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'บันทึกเพิ่มเติม...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorder)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: inputBorder)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor)),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: textLabel),
                        const SizedBox(width: 6),
                        _locating
                            ? Text('กำลังระบุตำแหน่ง...',
                                style:
                                    TextStyle(fontSize: 13, color: textLabel))
                            : Text(
                                _lat != null
                                    ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                    : 'ไม่สามารถระบุตำแหน่งได้',
                                style:
                                    TextStyle(fontSize: 13, color: textValue),
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('ยกเลิก'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryBtn,
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
}
