import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../providers/measurements_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/save_modal.dart';
import '../models/sensor_data.dart';
import '../theme/app_colors.dart';

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
    final saved = measurements.filteredMeasurements;
    if (saved.isNotEmpty) return saved.first;
    return const _DefaultSensorData();
  }

  DateTime? _getActiveLastUpdate(BleService ble, WiFiService wifi, MeasurementsProvider measurements) {
    if (_connectionMode == ConnectionMode.wifi && wifi.isConnected && wifi.lastUpdate != null) return wifi.lastUpdate;
    if (_connectionMode == ConnectionMode.ble && ble.isConnected && ble.lastUpdate != null) return ble.lastUpdate;
    if (ble.isConnected && ble.lastUpdate != null) return ble.lastUpdate;
    if (wifi.isConnected && wifi.lastUpdate != null) return wifi.lastUpdate;
    final saved = measurements.filteredMeasurements;
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
                        measurements.filteredMeasurements.isNotEmpty;
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
                _ConnectionPill(
                  isConnected: isAnyConnected,
                  mode: isAnyConnected 
                      ? (ble.isConnected ? ConnectionMode.ble : ConnectionMode.wifi)
                      : _connectionMode,
                ),
              ],
            ),

            // — Device info —
            if (isAnyConnected) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(ble.isConnected ? Icons.bluetooth_connected : Icons.wifi,
                      color: context.colors.primaryBtn, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    ble.isConnected 
                        ? ((ble.connectedDevice != null && ble.connectedDevice!.platformName.isNotEmpty)
                            ? ble.connectedDevice!.platformName
                            : 'SoilSensor (Bluetooth)')
                        : 'SoilSensor (WiFi)',
                    style: TextStyle(
                        color: context.colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ═══════════════════════════════════════════
            // When NOT connected: show inline scan UI
            // ═══════════════════════════════════════════
            if (!isAnyConnected) ...[
              // — Centered scan card —
              const SizedBox(height: 20),

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
                        child: _ModeTab(
                          icon: Icons.wifi,
                          label: 'WiFi',
                          isSelected: _connectionMode == ConnectionMode.wifi,
                          onTap: () => setState(() => _connectionMode = ConnectionMode.wifi),
                        ),
                      ),
                      Expanded(
                        child: _ModeTab(
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
                        _ScanAnimation(
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
                ...ble.foundDevices.map((device) => _DeviceCard(
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
              // When connected OR has cached data: show sensors
              // ═══════════════════════════════════════════

              // — Last update —
              _InfoRow(
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
                            onSaved: () => Navigator.of(context).pop(),
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

// — Small helper widgets —

class _ConnectionPill extends StatelessWidget {
  final bool isConnected;
  final ConnectionMode mode;
  const _ConnectionPill({required this.isConnected, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isConnected
            ? context.colors.statusConnectedBg
            : context.colors.statusDisconnectedBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isConnected
                  ? context.colors.statusDotConnected
                  : context.colors.statusDotDisconnected,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          if (isConnected) ...[
            Icon(mode == ConnectionMode.ble ? Icons.bluetooth : Icons.wifi,
                size: 10, color: context.colors.statusTextConnected),
            const SizedBox(width: 3),
          ],
          Text(
            isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isConnected
                  ? context.colors.statusTextConnected
                  : context.colors.statusTextDisconnected,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.colors.textMuted),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.textNormal)),
      ],
    );
  }
}

// — Scan animation (moved from scan_screen) —

class _ScanAnimation extends StatefulWidget {
  final bool isScanning;
  final IconData icon;
  const _ScanAnimation({required this.isScanning, this.icon = Icons.bluetooth});
  @override
  State<_ScanAnimation> createState() => _ScanAnimationState();
}

class _ScanAnimationState extends State<_ScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _animation = Tween<double>(begin: 0.8, end: 1.4)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isScanning)
            AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => Container(
                width: 80 * _animation.value,
                height: 80 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryBtn
                      .withValues(alpha: 0.12 * (2 - _animation.value)),
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isScanning
                  ? context.colors.primaryBtn
                  : context.colors.cardBg,
            ),
            child: Icon(widget.icon,
                color:
                    widget.isScanning ? Colors.white : context.colors.textMuted,
                size: 30),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primaryBtn.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, 
                size: 16, 
                color: isSelected ? context.colors.primaryBtn : context.colors.textMuted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? context.colors.primaryBtn : context.colors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// — Device card (moved from scan_screen) —

class _DeviceCard extends StatelessWidget {
  final dynamic device;
  final bool isConnected;
  final VoidCallback onConnect;

  const _DeviceCard(
      {required this.device,
      required this.isConnected,
      required this.onConnect});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isConnected
                ? context.colors.successBannerBorder
                : context.colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isConnected
                  ? context.colors.successBannerBg
                  : context.colors.cardBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bluetooth,
                color: isConnected
                    ? context.colors.primaryBtn
                    : context.colors.textMuted,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.platformName.isNotEmpty
                      ? device.platformName
                      : 'Unknown',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: context.colors.textNormal),
                ),
                Text(device.remoteId.toString(),
                    style: TextStyle(
                        fontSize: 11, color: context.colors.textMuted)),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.successBannerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('เชื่อมต่อแล้ว',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.colors.successBannerText)),
            )
          else
            FilledButton(
              onPressed: onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primaryBtn,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child:
                  const Text('เชื่อมต่อ', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
