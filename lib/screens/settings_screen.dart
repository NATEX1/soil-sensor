import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../providers/measurements_provider.dart';
import '../providers/theme_provider.dart';

const _green600 = Color(0xFF16a34a);

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final themeProvider = context.watch<ThemeProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final headerBg = isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
    final headerSubtitle =
        isDark ? const Color(0xFF6b7280) : const Color(0xFFbbf7d0);
    final primaryBtn =
        isDark ? const Color(0xFF15803d) : const Color(0xFF16a34a);
    final switchColor =
        isDark ? const Color(0xFF22c55e) : const Color(0xFF16a34a);
    final statusConnectedBg =
        isDark ? const Color(0xFF052e16) : const Color(0xFFdcfce7);
    final statusDisconnectedBg =
        isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6);
    final statusDotConnected = const Color(0xFF22c55e);
    final statusDotDisconnected =
        isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final statusTextConnected =
        isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);
    final statusTextDisconnected =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF9ca3af);
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final dividerColor =
        isDark ? const Color(0xFF2d3748) : const Color(0xFFf3f4f6);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: headerBg,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
            child: Row(
              children: [
                Icon(Icons.settings,
                    color: isDark ? const Color(0xFF4ade80) : Colors.white,
                    size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ตั้งค่า',
                        style: TextStyle(
                            color:
                                isDark ? const Color(0xFFf9fafb) : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('การตั้งค่าแอปพลิเคชัน',
                        style: TextStyle(color: headerSubtitle, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // BLE Section
                const _SectionLabel(label: 'Bluetooth (BLE)'),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      label: 'สถานะการเชื่อมต่อ',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ble.isConnected
                              ? statusConnectedBg
                              : statusDisconnectedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: ble.isConnected
                                    ? statusDotConnected
                                    : statusDotDisconnected,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ble.isConnected
                                  ? 'เชื่อมต่อแล้ว'
                                  : 'ไม่ได้เชื่อมต่อ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ble.isConnected
                                    ? statusTextConnected
                                    : statusTextDisconnected,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (ble.isConnected && ble.connectedDevice != null) ...[
                      Divider(height: 1, color: dividerColor),
                      _SettingsRow(
                          label: 'ชื่ออุปกรณ์',
                          value: ble.connectedDevice!.platformName.isNotEmpty
                              ? ble.connectedDevice!.platformName
                              : 'SoilSensor'),
                      Divider(height: 1, color: dividerColor),
                      _SettingsRow(
                          label: 'MAC Address',
                          value: ble.connectedDevice!.remoteId.toString(),
                          mono: true),
                      Divider(height: 1, color: dividerColor),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('ตัดการเชื่อมต่อ',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        onTap: () => _confirmDisconnect(context, ble),
                        dense: true,
                      ),
                    ],
                    if (!ble.isConnected)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text('ไม่มีอุปกรณ์ที่เชื่อมต่ออยู่',
                            style: TextStyle(fontSize: 14, color: textMuted)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Appearance Section
                const _SectionLabel(label: 'การแสดงผล'),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      label: 'โหมดมืด',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: switchColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // App Info Section
                const _SectionLabel(label: 'ข้อมูลแอปพลิเคชัน'),
                _SettingsCard(
                  children: [
                    _SettingsRow(label: 'เวอร์ชัน', value: '1.0.0'),
                    Divider(height: 1, color: dividerColor),
                    _SettingsRow(label: 'Framework', value: 'Flutter'),
                    Divider(height: 1, color: dividerColor),
                    _SettingsRow(label: 'ฐานข้อมูล', value: 'SQLite (sqflite)'),
                    Divider(height: 1, color: dividerColor),
                    _SettingsRow(
                        label: 'BLE Library', value: 'flutter_blue_plus'),
                  ],
                ),
                const SizedBox(height: 16),

                // Database Section
                const _SectionLabel(label: 'ฐานข้อมูล'),
                _SettingsCard(
                  children: [
                    ListTile(
                      leading:
                          const Icon(Icons.dataset, color: Color(0xFF16a34a)),
                      title: const Text('เพิ่มข้อมูลตัวอย่าง 100 รายการ',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('สร้างข้อมูลจำลองสำหรับทดสอบ',
                          style: TextStyle(fontSize: 12)),
                      onTap: () => _seedData(context),
                    ),
                    Divider(height: 1, color: dividerColor),
                    ListTile(
                      leading: const Icon(Icons.delete_outline,
                          color: Color(0xFFef4444)),
                      title: const Text('ล้างข้อมูลทั้งหมด',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('ลบข้อมูลการวัดทั้งหมด',
                          style: TextStyle(fontSize: 12)),
                      onTap: () => _clearData(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Warning
                _WarningBox(
                  text:
                      'ต้องเปิด Bluetooth และอนุญาตสิทธิ์ Location บนอุปกรณ์\nต้องใช้ Android 6.0+ หรือ iOS 13+',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, BleService ble) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ตัดการเชื่อมต่อ'),
        content: const Text('ต้องการตัดการเชื่อมต่อ BLE หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ble.disconnect();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('ไม่สามารถตัดการเชื่อมต่อได้'),
                        backgroundColor: Color(0xFFef4444)),
                  );
                }
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFef4444)),
            child: const Text('ตัดการเชื่อมต่อ'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedData(BuildContext context) async {
    try {
      await DatabaseService.seedDummyData(count: 100);
      if (context.mounted) {
        context.read<MeasurementsProvider>().fetch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('เพิ่มข้อมูลตัวอย่าง 100 รายการสำเร็จ'),
              backgroundColor: Color(0xFF22c55e)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: const Color(0xFFef4444)),
        );
      }
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ล้างข้อมูลทั้งหมด'),
        content: const Text(
            'ต้องการลบข้อมูลการวัดทั้งหมดหรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFef4444)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ล้างข้อมูล')),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final db = await DatabaseService.database;
        await db.delete('measurements');
        if (context.mounted) {
          context.read<MeasurementsProvider>().fetch();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('ล้างข้อมูลทั้งหมดสำเร็จ'),
                backgroundColor: Color(0xFF22c55e)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'),
                backgroundColor: const Color(0xFFef4444)),
          );
        }
      }
    }
  }
}

class _WarningBox extends StatelessWidget {
  final String text;
  const _WarningBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF422006) : const Color(0xFFfffbeb);
    final border = isDark ? const Color(0xFF92400e) : const Color(0xFFfde68a);
    const textColor = Color(0xFFfbbf24);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: textColor),
            SizedBox(width: 6),
            Text('หมายเหตุสำคัญ',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ]),
          const SizedBox(height: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, color: textColor, height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final bool mono;

  const _SettingsRow(
      {required this.label, this.value, this.trailing, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: cs.onSurface.withOpacity(0.7))),
          if (trailing != null)
            trailing!
          else if (value != null)
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
