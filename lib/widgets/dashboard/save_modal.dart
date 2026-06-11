import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/sensor_data.dart';
import '../../services/api_service.dart';
import '../../providers/plot_provider.dart';
import '../../theme/app_colors.dart';
import '../../screens/dashboard/create_plot_screen.dart';

class SaveModal extends StatefulWidget {
  final SensorData? sensorData;
  final VoidCallback onClose;
  final VoidCallback onSaved;
  final String? plotId;
  final String? initialPointName;
  final SampleMethod? initialSampleMethod;
  final double? sensorLat;
  final double? sensorLng;

  const SaveModal(
      {super.key,
      required this.sensorData,
      required this.onClose,
      required this.onSaved,
      this.plotId,
      this.initialPointName,
      this.initialSampleMethod,
      this.sensorLat,
      this.sensorLng});

  @override
  State<SaveModal> createState() => _SaveModalState();
}

class _SaveModalState extends State<SaveModal> {
  SampleMethod _sampleMethod = SampleMethod.surface0_15;
  final _notesController = TextEditingController();
  final _pointNameController = TextEditingController();
  final _harvestAgeController = TextEditingController();
  String? _soilType;
  double? _lat;
  double? _lng;
  bool _saving = false;
  bool _locating = false;
  bool _useSensorGps = false;
  String? _error;

  // Plot selection
  PlotRecord? _selectedPlot;

  @override
  void initState() {
    super.initState();
    _getLocation();
    // Pre-fill for re-measure
    if (widget.initialPointName != null) {
      _pointNameController.text = widget.initialPointName!;
    }
    if (widget.initialSampleMethod != null) {
      _sampleMethod = widget.initialSampleMethod!;
    }
    // If plotId is provided (re-measure), pre-select that plot
    if (widget.plotId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final plotProvider = context.read<PlotProvider>();
        final match = plotProvider.availablePlots
            .where((p) => p.id == widget.plotId)
            .firstOrNull;
        if (match != null) {
          setState(() => _selectedPlot = match);
        }
      });
    } else {
      // Pre-select the current plot from provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final plotProvider = context.read<PlotProvider>();
        if (plotProvider.currentPlot != null) {
          setState(() => _selectedPlot = plotProvider.currentPlot);
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pointNameController.dispose();
    _harvestAgeController.dispose();
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

  Future<void> _openCreatePlotScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePlotScreen()),
    );
    if (result == true) {
      if (!mounted) return;
      final plots = context.read<PlotProvider>().availablePlots;
      if (plots.isNotEmpty) {
        setState(() {
          _selectedPlot = plots.first;
        });
      }
    }
  }

  Future<void> _save({SensorData? overrideData}) async {
    final dataToSave = overrideData ?? widget.sensorData;
    if (dataToSave == null) return;
    if (_selectedPlot == null) {
      setState(() => _error = 'กรุณาเลือกแปลงก่อนบันทึก');
      return;
    }
    if (_pointNameController.text.trim().isEmpty) {
      setState(() => _error = 'กรุณาระบุชื่อจุดเก็บตัวอย่าง');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final useSensor = _useSensorGps &&
          widget.sensorLat != null &&
          widget.sensorLng != null &&
          widget.sensorLat != 0.0;

      await ApiService.saveMeasurement(
        sampleMethod: _sampleMethod,
        pointName: _pointNameController.text.isEmpty
            ? null
            : _pointNameController.text,
        plotId: _selectedPlot!.id,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        lat: useSensor ? widget.sensorLat! : (_lat ?? 0),
        lng: useSensor ? widget.sensorLng! : (_lng ?? 0),
        ph: dataToSave.ph,
        nitrogen: dataToSave.nitrogen,
        phosphorus: dataToSave.phosphorus,
        potassium: dataToSave.potassium,
        moisture: dataToSave.moisture,
        temperature: dataToSave.temperature,
        ec: dataToSave.ec,
        salinity: dataToSave.salinity,
        soilType: _soilType,
        harvestAge: double.tryParse(_harvestAgeController.text),
      );
      // Update the current plot in provider
      if (mounted) {
        context.read<PlotProvider>().selectPlot(_selectedPlot!);
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plotProvider = context.watch<PlotProvider>();
    final plots = plotProvider.availablePlots;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
                          Icon(Icons.error_outline,
                              size: 16, color: context.colors.errorText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: TextStyle(
                                    color: context.colors.errorText,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // ═══════════════════════════════════════════
                  // PLOT SELECTION SECTION
                  // ═══════════════════════════════════════════
                  Row(
                    children: [
                      Icon(Icons.landscape,
                          size: 16, color: context.colors.primaryBtn),
                      const SizedBox(width: 6),
                      Text('เลือกแปลง',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textNormal)),
                      const Spacer(),
                      if (_selectedPlot != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.colors.primaryBtn
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('เลือกแล้ว ✓',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primaryBtn)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Existing plots as selectable cards
                  if (plots.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount:
                            plots.length + 1, // +1 for "create new" button
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          // Last item is the "create new" button
                          if (index == plots.length) {
                            return _buildCreateNewPlotButton();
                          }
                          final plot = plots[index];
                          final isSelected = _selectedPlot?.id == plot.id;
                          return _buildPlotCard(plot, isSelected);
                        },
                      ),
                    )
                  else
                    // No plots yet — show create button prominently
                    _buildEmptyPlotState(),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════
                  // POINT NAME
                  // ═══════════════════════════════════════════
                  Text('ชื่อจุดเก็บตัวอย่าง',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _pointNameController,
                    style: TextStyle(
                        fontSize: 14, color: context.colors.textNormal),
                    decoration: InputDecoration(
                      hintText: 'เช่น จุดทดสอบที่ 1',
                      hintStyle: TextStyle(
                          color:
                              context.colors.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: context.colors.cardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: context.colors.borderColor
                                  .withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: context.colors.primaryBtn
                                  .withValues(alpha: 0.5))),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════
                  // SAMPLE METHOD
                  // ═══════════════════════════════════════════
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
                      border: Border.all(
                          color: context.colors.borderColor
                              .withValues(alpha: 0.5)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RadioGroup<SampleMethod>(
                      groupValue: _sampleMethod,
                      onChanged: (v) => setState(() => _sampleMethod = v!),
                      child: Column(
                        children: SampleMethod.values
                            .map(
                              (sm) => RadioListTile<SampleMethod>(
                                value: sm,
                                title: Text(sampleMethodLabels[sm]!,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: context.colors.textNormal)),
                                activeColor: context.colors.primaryBtn,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                dense: true,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════
                  // ADVANCED ML OPTIONS (OPTIONAL)
                  // ═══════════════════════════════════════════
                  Text('ข้อมูลเพิ่มเติมสำหรับ ML (ตัวเลือก)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _soilType,
                          decoration: InputDecoration(
                            labelText: 'ประเภทดิน',
                            labelStyle: TextStyle(color: context.colors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: context.colors.cardBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.colors.borderColor.withValues(alpha: 0.5))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          dropdownColor: context.colors.cardBg,
                          style: TextStyle(color: context.colors.textNormal, fontSize: 14),
                          items: const [
                            DropdownMenuItem(value: 'clay_loam', child: Text('ดินร่วนเหนียว')),
                            DropdownMenuItem(value: 'loam', child: Text('ดินร่วน')),
                            DropdownMenuItem(value: 'loamy_sand', child: Text('ดินทรายร่วน')),
                            DropdownMenuItem(value: 'sandy', child: Text('ดินทราย')),
                            DropdownMenuItem(value: 'sandy_loam', child: Text('ดินร่วนปนทราย')),
                          ],
                          onChanged: (v) => setState(() => _soilType = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _harvestAgeController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 14, color: context.colors.textNormal),
                          decoration: InputDecoration(
                            labelText: 'อายุเก็บเกี่ยว (เดือน)',
                            labelStyle: TextStyle(color: context.colors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: context.colors.cardBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.colors.borderColor.withValues(alpha: 0.5))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════
                  // NOTES
                  // ═══════════════════════════════════════════
                  Text('หมายเหตุ',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(
                        fontSize: 14, color: context.colors.textNormal),
                    decoration: InputDecoration(
                      hintText: 'บันทึกเพิ่มเติม...',
                      hintStyle: TextStyle(
                          color:
                              context.colors.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: context.colors.cardBg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: context.colors.borderColor
                                  .withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: context.colors.primaryBtn
                                  .withValues(alpha: 0.5))),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════
                  // LOCATION — GPS source selector
                  // ═══════════════════════════════════════════
                  Text('ตำแหน่งพิกัด (GPS)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textNormal)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: context.colors.borderColor
                              .withValues(alpha: 0.5)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: false,
                          groupValue: _useSensorGps,
                          onChanged: (v) => setState(() => _useSensorGps = v!),
                          activeColor: context.colors.primaryBtn,
                          title: Row(
                            children: [
                              Icon(Icons.smartphone,
                                  size: 18,
                                  color: !_useSensorGps
                                      ? context.colors.primaryBtn
                                      : context.colors.textMuted),
                              const SizedBox(width: 8),
                              Text('พิกัดจากมือถือ',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: context.colors.textNormal)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(left: 26, top: 4),
                            child: _locating
                                ? Text('กำลังระบุตำแหน่ง...',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: context.colors.textMuted))
                                : Text(
                                    _lat != null
                                        ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                        : 'ไม่สามารถระบุตำแหน่งได้',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: !_useSensorGps
                                            ? context.colors.primaryBtn
                                            : context.colors.textMuted),
                                  ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                        Divider(
                            height: 1,
                            color: context.colors.borderColor
                                .withValues(alpha: 0.5)),
                        if (widget.sensorLat != null &&
                            widget.sensorLng != null &&
                            widget.sensorLat != 0.0)
                          RadioListTile<bool>(
                            value: true,
                            groupValue: _useSensorGps,
                            onChanged: (v) =>
                                setState(() => _useSensorGps = v!),
                            activeColor: context.colors.primaryBtn,
                            title: Row(
                              children: [
                                Icon(Icons.sensors,
                                    size: 18,
                                    color: _useSensorGps
                                        ? context.colors.primaryBtn
                                        : context.colors.textMuted),
                                const SizedBox(width: 8),
                                Text('พิกัดจากเซ็นเซอร์ (Device)',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: context.colors.textNormal)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(left: 26, top: 4),
                              child: Text(
                                '${widget.sensorLat!.toStringAsFixed(5)}, ${widget.sensorLng!.toStringAsFixed(5)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _useSensorGps
                                        ? context.colors.primaryBtn
                                        : context.colors.textMuted),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                Icon(Icons.sensors_off,
                                    size: 18,
                                    color: context.colors.textMuted
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 8),
                                Text('ไม่พบพิกัด GPS จากเซ็นเซอร์',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: context.colors.textMuted
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════
                  // ACTION BUTTONS
                  // ═══════════════════════════════════════════
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          style: OutlinedButton.styleFrom(
                              foregroundColor: context.colors.textNormal,
                              side:
                                  BorderSide(color: context.colors.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          child: const Text('ยกเลิก',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed:
                              (_saving || _selectedPlot == null) ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.colors.primaryBtn,
                            disabledBackgroundColor: context.colors.textMuted
                                .withValues(alpha: 0.15),
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

  // ─── Plot Card ──────────────────────────────────────────────────────

  Widget _buildPlotCard(PlotRecord plot, bool isSelected) {
    final dateStr =
        '${plot.createdAt.day.toString().padLeft(2, '0')}/${plot.createdAt.month.toString().padLeft(2, '0')}/${plot.createdAt.year}';
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPlot = plot;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primaryBtn.withValues(alpha: 0.12)
              : context.colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? context.colors.primaryBtn
                : context.colors.borderColor.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.landscape,
                  size: 16,
                  color: isSelected
                      ? context.colors.primaryBtn
                      : context.colors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    plot.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? context.colors.primaryBtn
                          : context.colors.textNormal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  dateStr,
                  style:
                      TextStyle(fontSize: 10, color: context.colors.textMuted),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: context.colors.primaryBtn.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${plot.measurementCount} จุด',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primaryBtn),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Create New Plot Button ─────────────────────────────────────────

  Widget _buildCreateNewPlotButton() {
    return GestureDetector(
      onTap: _openCreatePlotScreen,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.colors.borderColor.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 24, color: context.colors.primaryBtn),
            const SizedBox(height: 6),
            Text('สร้างแปลงใหม่',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primaryBtn),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── Empty State (No Plots) ─────────────────────────────────────────

  Widget _buildEmptyPlotState() {
    return GestureDetector(
      onTap: _openCreatePlotScreen,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.primaryBtn.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: context.colors.primaryBtn.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.add_location_alt_outlined,
                size: 36, color: context.colors.primaryBtn),
            const SizedBox(height: 8),
            Text('ยังไม่มีแปลง',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textNormal)),
            const SizedBox(height: 4),
            Text('กดเพื่อสร้างแปลงแรกของคุณ',
                style:
                    TextStyle(fontSize: 12, color: context.colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
