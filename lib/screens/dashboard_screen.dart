import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../providers/measurements_provider.dart';
import '../widgets/dashboard/sensor_card.dart';
import '../widgets/dashboard/save_modal.dart';
import '../models/sensor_data.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard/connection_pill.dart';
import '../widgets/dashboard/info_row.dart';
import '../widgets/dashboard/scan_animation.dart';
import '../widgets/dashboard/mode_tab.dart';
import '../widgets/dashboard/device_card.dart';

const _sensorKeys = [
  ('ph', 'pH', ''),
  ('nitrogen', 'ไนโตรเจน (N)', 'mg/kg'),
  ('phosphorus', 'ฟอสฟอรัส (P)', 'mg/kg'),
  ('potassium', 'โพแทสเซียม (K)', 'mg/kg'),
  ('moisture', 'ความชื้น', '%'),
  ('temperature', 'อุณหภูมิ', '°C'),
  ('ec', 'EC', 'dS/m'),
  ('salinity', 'ความเค็ม', 'ppt'),
];

class _DefaultSensorData extends SensorData {
  const _DefaultSensorData()
      : super(
          ph: 0, nitrogen: 0, phosphorus: 0, potassium: 0,
          moisture: 0, temperature: 0, ec: 0, salinity: 0,
        );
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

enum ConnectionMode { ble, wifi }

class _DashboardScreenState extends State<DashboardScreen> {
  ConnectionMode _connectionMode = ConnectionMode.wifi;

  String _formatLastUpdate(DateTime? date) {
    if (date == null) return 'ยังไม่มีข้อมูล';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  SensorData _getActiveData(BleService ble, WiFiService wifi, MeasurementsProvider measurements) {
    if (_connectionMode == ConnectionMode.wifi && wifi.isConnected && wifi.sensorData != null) return wifi.sensorData!;
    if (_connectionMode == ConnectionMode.ble && ble.isConnected && ble.sensorData != null) return ble.sensorData!;
    if (ble.isConnected && ble.sensorData != null) return ble.sensorData!;
    if (wifi.isConnected && wifi.sensorData != null) return wifi.sensorData!;
    final saved = measurements.allMeasurements;
    if (saved.isNotEmpty) return saved.first;
    return const _DefaultSensorData();
  }

  DateTime? _getActiveLastUpdate(BleService ble, WiFiService wifi, MeasurementsProvider measurements) {
    if (_connectionMode == ConnectionMode.wifi && wifi.isConnected && wifi.lastUpdate != null) return wifi.lastUpdate;
    if (_connectionMode == ConnectionMode.ble && ble.isConnected && ble.lastUpdate != null) return ble.lastUpdate;
    if (ble.isConnected && ble.lastUpdate != null) return ble.lastUpdate;
    if (wifi.isConnected && wifi.lastUpdate != null) return wifi.lastUpdate;
    final saved = measurements.allMeasurements;
    if (saved.isNotEmpty && saved.first.measuredAt != null) return saved.first.measuredAt;
    return null;
  }

  Future<void> _connectDevice(dynamic device) async {
    try {
      await context.read<BleService>().connect(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เชื่อมต่อกับ ${device.platformName.isNotEmpty ? device.platformName : "อุปกรณ์"} สำเร็จ'),
            backgroundColor: const Color(0xFF16a34a),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่'),
              backgroundColor: Color(0xFFef4444)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final wifi = context.watch<WiFiService>();
    final measurements = context.watch<MeasurementsProvider>();
    final activeData = _getActiveData(ble, wifi, measurements);
    
    final isAnyConnected = ble.isConnected || wifi.isConnected;
    final hasRealData = (ble.isConnected && ble.sensorData != null) || 
                        (wifi.isConnected && wifi.sensorData != null) ||
                        measurements.allMeasurements.isNotEmpty;
    final activeLastUpdate = _getActiveLastUpdate(ble, wifi, measurements);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: RefreshIndicator(
        color: context.colors.primaryBtn,
        onRefresh: () async => setState(() {}),
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, bottomPadding + 24),
          children: [
            // — Minimal Header —
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SoilSensor',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textNormal,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text('ระบบวิเคราะห์ดินอัจฉริยะ',
                        style: TextStyle(
                            fontSize: 13,
                            color: context.colors.textMuted)),
                  ],
                ),
                ConnectionPill(
                  isConnected: _connectionMode == ConnectionMode.ble ? ble.isConnected : wifi.isConnected,
                  mode: _connectionMode,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // — Mode Selector (Always Visible) —
            Center(
              child: Container(
                width: 260,
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ModeTab(
                        icon: Icons.wifi,
                        label: 'WiFi',
                        isSelected: _connectionMode == ConnectionMode.wifi,
                        onTap: () => setState(() => _connectionMode = ConnectionMode.wifi),
                      ),
                    ),
                    Expanded(
                      child: ModeTab(
                        icon: Icons.bluetooth,
                        label: 'Bluetooth',
                        isSelected: _connectionMode == ConnectionMode.ble,
                        onTap: () => setState(() => _connectionMode = ConnectionMode.ble),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // Active Connection Check
            // ═══════════════════════════════════════════
            if ((_connectionMode == ConnectionMode.wifi && !wifi.isConnected) || 
                (_connectionMode == ConnectionMode.ble && !ble.isConnected)) ...[
              // — Show scan UI for the selected mode —

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.colors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    final isScanning = _connectionMode == ConnectionMode.ble ? ble.isScanning : wifi.isScanning;
                    return Column(
                      children: [
                        // Icon
                        ScanAnimation(
                          isScanning: isScanning,
                          icon: _connectionMode == ConnectionMode.ble ? Icons.bluetooth : Icons.wifi,
                        ),
                        const SizedBox(height: 20),

                        // Status text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            isScanning
                                ? 'กำลังค้นหาอุปกรณ์...'
                                : 'แตะเพื่อค้นหา SoilSensor',
                            key: ValueKey(isScanning),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textNormal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'เชื่อมต่ออุปกรณ์เพื่อเริ่มวิเคราะห์ดิน',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textMuted,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: isScanning
                                    ? (_connectionMode == ConnectionMode.ble 
                                        ? () => context.read<BleService>().stopScan() 
                                        : () => context.read<WiFiService>().stopScan())
                                    : () => _connectionMode == ConnectionMode.ble
                                        ? context.read<BleService>().startScan()
                                        : context.read<WiFiService>().scanForDevice(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isScanning
                                      ? context.colors.textMuted.withValues(alpha: 0.15)
                                      : context.colors.primaryBtn,
                                  foregroundColor: isScanning
                                      ? context.colors.textNormal
                                      : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                icon: Icon(
                                    isScanning
                                        ? Icons.stop_rounded
                                        : (_connectionMode == ConnectionMode.ble ? Icons.bluetooth_searching : Icons.wifi_find),
                                    size: 18),
                                label: Text(
                                    isScanning ? 'หยุด' : 'เริ่มสแกน',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.read<BleService>().startDemoMode();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.colors.primaryBtn,
                                  side: BorderSide(
                                      color: context.colors.borderColor),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.science_outlined,
                                    size: 18),
                                label: const Text('Demo',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                ),
              ),

              // — Error —
              Builder(
                builder: (context) {
                  final currentError = _connectionMode == ConnectionMode.ble ? ble.error : wifi.error;
                  if (currentError != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.colors.errorBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.errorBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                size: 15, color: context.colors.errorText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(currentError,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.errorText)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
              ),

              // — Found devices —
              if (_connectionMode == ConnectionMode.ble && ble.foundDevices.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text('พบอุปกรณ์',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textNormal)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.primaryBtn.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${ble.foundDevices.length}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.colors.primaryBtn)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...ble.foundDevices.map((device) => DeviceCard(
                      device: device,
                      isConnected:
                          ble.connectedDevice?.remoteId == device.remoteId,
                      onConnect: () => _connectDevice(device),
                    )),
              ],

              const SizedBox(height: 16),
              // Note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline,
                      size: 12, color: context.colors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    _connectionMode == ConnectionMode.ble
                        ? 'ต้องเปิด Bluetooth และอนุญาตสิทธิ์ Location'
                        : 'ต้องเชื่อมต่อ WiFi วงเดียวกันกับอุปกรณ์',
                    style: TextStyle(
                        fontSize: 11, color: context.colors.textMuted),
                  ),
                ],
              ),
            ] else ...[
              // ═══════════════════════════════════════════
              // When connected: show sensors
              // ═══════════════════════════════════════════
              
              // — Device info —
              Row(
                children: [
                  Icon(_connectionMode == ConnectionMode.ble ? Icons.bluetooth_connected : Icons.wifi,
                      color: context.colors.primaryBtn, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    _connectionMode == ConnectionMode.ble 
                        ? ((ble.connectedDevice != null && ble.connectedDevice!.platformName.isNotEmpty)
                            ? ble.connectedDevice!.platformName
                            : 'SoilSensor (Bluetooth)')
                        : 'SoilSensor (WiFi)',
                    style: TextStyle(
                        color: context.colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // — Last update —
              InfoRow(
                icon: Icons.access_time_rounded,
                label: 'อัปเดตล่าสุด',
                value: _formatLastUpdate(activeLastUpdate),
              ),
              if (!isAnyConnected && hasRealData) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 21),
                    Icon(Icons.info_outline,
                        size: 12, color: context.colors.warningText),
                    const SizedBox(width: 4),
                    Text('ข้อมูลจากแคช',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.colors.warningText)),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // — Sensor Grid —
              Text('ค่าเซ็นเซอร์',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textNormal)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: _sensorKeys.map((entry) {
                  final (key, label, unit) = entry;
                  return SensorCard(
                    label: label,
                    value: activeData[key],
                    unit: unit,
                    thresholdKey: key,
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // — Action Buttons —
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => SaveModal(
                            sensorData: activeData,
                            onClose: () => Navigator.of(context).pop(),
                            onSaved: () {
                              Navigator.of(context).pop();
                              context.read<MeasurementsProvider>().fetch();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('บันทึกข้อมูลสำเร็จ', style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: context.colors.primaryBtn,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('บันทึก',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/recommend'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.primaryBtn,
                        side: BorderSide(color: context.colors.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.lightbulb_outline, size: 18),
                      label: const Text('คำแนะนำ',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

