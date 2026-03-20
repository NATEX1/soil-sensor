import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../widgets/sensor_card.dart';
import '../widgets/save_modal.dart';
import '../models/calculations.dart';

const _green600 = Color(0xFF16a34a);

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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _saveModalVisible = false;

  String _formatLastUpdate(DateTime? date) {
    if (date == null) return 'ยังไม่มีข้อมูล';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final headerBg = isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
    final headerSubtitle =
        isDark ? const Color(0xFF6b7280) : const Color(0xFFbbf7d0);
    final headerIcon =
        isDark ? const Color(0xFF4ade80) : const Color(0xFFbbf7d0);
    final statusConnectedBg = const Color(0xFF22c55e);
    final statusDisconnectedBg = const Color(0xFFef4444);
    final statusDotConnected =
        isDark ? const Color(0xFF86efac) : const Color(0xFFbbf7d0);
    final statusDotDisconnected =
        isDark ? const Color(0xFFfca5a5) : const Color(0xFFfecaca);
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF9ca3af);
    final textNormal =
        isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);
    final textLabel =
        isDark ? const Color(0xFFd1d5db) : const Color(0xFF4b5563);
    final warningOrange =
        isDark ? const Color(0xFFfbbf24) : const Color(0xFFf97316);
    final iconMuted =
        isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final primaryBtn =
        isDark ? const Color(0xFF15803d) : const Color(0xFF16a34a);
    final outlineBtn =
        isDark ? const Color(0xFF16a34a) : const Color(0xFF16a34a);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            color: _green600,
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    color: headerBg,
                    padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.eco,
                                    color: isDark
                                        ? const Color(0xFF4ade80)
                                        : Colors.white,
                                    size: 24),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SoilSensor',
                                        style: TextStyle(
                                            color: isDark
                                                ? const Color(0xFFf9fafb)
                                                : Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    Text('ระบบวิเคราะห์ดินอัจฉริยะ',
                                        style: TextStyle(
                                            color: headerSubtitle,
                                            fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: ble.isConnected
                                    ? statusConnectedBg
                                    : statusDisconnectedBg.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: ble.isConnected
                                          ? statusDotConnected
                                          : statusDotDisconnected,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ble.isConnected
                                        ? 'เชื่อมต่อแล้ว'
                                        : 'ไม่ได้เชื่อมต่อ',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (ble.isConnected && ble.connectedDevice != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.bluetooth_connected,
                                  color: headerIcon, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${ble.connectedDevice!.platformName} · ${ble.connectedDevice!.remoteId.toString().substring(0, 8)}...',
                                style: TextStyle(
                                    color: headerSubtitle, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Last update card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('อัปเดตล่าสุด',
                                style:
                                    TextStyle(fontSize: 12, color: textMuted)),
                            const SizedBox(height: 2),
                            Text(_formatLastUpdate(ble.lastUpdate),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textNormal)),
                            if (!ble.isConnected && ble.sensorData != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 14, color: warningOrange),
                                  const SizedBox(width: 4),
                                  Text('แสดงข้อมูลแคชล่าสุด',
                                      style: TextStyle(
                                          fontSize: 12, color: warningOrange)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Sensor grid
                      if (ble.sensorData != null) ...[
                        Text('ค่าเซ็นเซอร์',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textLabel)),
                        const SizedBox(height: 8),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.6,
                          children: _sensorKeys.map((entry) {
                            final (key, label, unit) = entry;
                            return SensorCard(
                              label: label,
                              value: ble.sensorData![key],
                              unit: unit,
                              thresholdKey: key,
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off, size: 40, color: iconMuted),
                              const SizedBox(height: 12),
                              Text(
                                  'ยังไม่มีข้อมูลเซ็นเซอร์\nกรุณาเชื่อมต่ออุปกรณ์ก่อน',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: textMuted, fontSize: 14)),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => context.go('/scan'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: primaryBtn,
                                    shape: const StadiumBorder()),
                                child: const Text('ไปสแกน BLE'),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: ble.sensorData != null
                                  ? () =>
                                      setState(() => _saveModalVisible = true)
                                  : null,
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryBtn,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.save, size: 18),
                              label: const Text('บันทึกผลการวัด',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: ble.sensorData != null
                                  ? () => context.push('/recommend')
                                  : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: outlineBtn,
                                side: BorderSide(
                                    color: ble.sensorData != null
                                        ? outlineBtn
                                        : borderColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              icon:
                                  const Icon(Icons.lightbulb_outline, size: 18),
                              label: const Text('ดูคำแนะนำ',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          if (_saveModalVisible)
            GestureDetector(
              onTap: () => setState(() => _saveModalVisible = false),
              child: Container(color: Colors.black54),
            ),
          if (_saveModalVisible)
            SaveModal(
              sensorData: ble.sensorData,
              onClose: () => setState(() => _saveModalVisible = false),
              onSaved: () => setState(() => _saveModalVisible = false),
            ),
        ],
      ),
    );
  }
}
