import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../providers/measurements_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/common/warning_box.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final themeProvider = context.watch<ThemeProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
        children: [
          // — Minimal Header —
          Text('การตั้งค่า',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textNormal,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text('จัดการแอปและอุปกรณ์',
              style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
          const SizedBox(height: 24),
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
                          color: ble.isConnected || ble.isDemoMode
                              ? context.colors.statusConnectedBg
                              : context.colors.statusDisconnectedBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: ble.isConnected || ble.isDemoMode
                                    ? context.colors.statusDotConnected
                                    : context.colors.statusDotDisconnected,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ble.isDemoMode 
                                ? 'โหมดจำลอง'
                                : (ble.isConnected
                                    ? 'เชื่อมต่อแล้ว'
                                    : 'ไม่ได้เชื่อมต่อ'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ble.isConnected || ble.isDemoMode
                                    ? context.colors.statusTextConnected
                                    : context.colors.statusTextDisconnected,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (ble.isConnected) ...[
                      if (ble.isDemoMode) ...[
                        Divider(height: 1, color: context.colors.dividerColor),
                        const _SettingsRow(label: 'ชื่ออุปกรณ์', value: 'Demo Sensor (Simulator)'),
                        Divider(height: 1, color: context.colors.dividerColor),
                        const _SettingsRow(label: 'โหมด', value: 'Demo Mode Active'),
                      ] else if (ble.connectedDevice != null) ...[
                        Divider(height: 1, color: context.colors.dividerColor),
                        _SettingsRow(
                            label: 'ชื่ออุปกรณ์',
                            value: ble.connectedDevice!.platformName.isNotEmpty
                                ? ble.connectedDevice!.platformName
                                : 'SoilSensor'),
                        Divider(height: 1, color: context.colors.dividerColor),
                        _SettingsRow(
                            label: 'MAC Address',
                            value: ble.connectedDevice!.remoteId.toString(),
                            mono: true),
                      ],
                      Divider(height: 1, color: context.colors.dividerColor),
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text('ตัดการเชื่อมต่อ',
                            style: TextStyle(
                                color: context.colors.errorText,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        onTap: () => _confirmDisconnect(context, ble),
                        dense: true,
                      ),
                    ],
                    if (!ble.isConnected) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ไม่มีอุปกรณ์ที่เชื่อมต่ออยู่',
                                style: TextStyle(fontSize: 14, color: context.colors.textMuted)),
                            TextButton(
                              onPressed: () => ble.startDemoMode(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: const StadiumBorder(),
                                backgroundColor: context.colors.primaryBtn.withValues(alpha: 0.1),
                                foregroundColor: context.colors.primaryBtn,
                              ),
                              child: const Text('ทดสอบ (Demo)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        activeThumbColor: context.colors.switchColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // App Info Section
                const _SectionLabel(label: 'ข้อมูลแอปพลิเคชัน'),
                _SettingsCard(
                  children: [
                    const _SettingsRow(label: 'เวอร์ชัน', value: '1.0.0'),
                    Divider(height: 1, color: context.colors.dividerColor),
                    const _SettingsRow(label: 'Framework', value: 'Flutter'),
                    Divider(height: 1, color: context.colors.dividerColor),
                    const _SettingsRow(label: 'ฐานข้อมูล', value: 'SQLite (sqflite)'),
                    Divider(height: 1, color: context.colors.dividerColor),
                    const _SettingsRow(
                        label: 'BLE Library', value: 'flutter_blue_plus'),
                  ],
                ),
                const SizedBox(height: 16),

                // App Customization Section
                const _SectionLabel(label: 'การตั้งค่าแอปพลิเคชัน'),
                _SettingsCard(
                  children: [
                    _ActionRow(
                      label: 'จัดการชนิดพืช',
                      showChevron: true,
                      onTap: () => context.push('/settings/plants'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Database Section
                const _SectionLabel(label: 'ฐานข้อมูล'),
                _SettingsCard(
                  children: [
                    _ActionRow(
                      label: 'เพิ่มข้อมูลตัวอย่าง 100 รายการ',
                      onTap: () => _seedData(context),
                    ),
                    Divider(height: 1, color: context.colors.dividerColor),
                    _ActionRow(
                      label: 'ล้างข้อมูลทั้งหมด',
                      isDestructive: true,
                      onTap: () => _clearData(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Warning
                const WarningBox(
                  title: 'ข้อควรระวัง',
                  content:
                      'ต้องเปิด Bluetooth และอนุญาตสิทธิ์ Location บนอุปกรณ์\nต้องใช้ Android 6.0+ หรือ iOS 13+',
                ),
                const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, BleService ble) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        title: Text('ยืนยันตัดการเชื่อมต่อ', style: TextStyle(color: context.colors.textNormal)),
        content: Text('คุณต้องการตัดการเชื่อมต่อจากอุปกรณ์ BLE ใช่หรือไม่?', style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.errorText,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ble.disconnect();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text('ไม่สามารถตัดการเชื่อมต่อได้'),
                        backgroundColor: context.colors.errorText),
                  );
                }
              }
            },
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
          SnackBar(
              content: const Text('เพิ่มข้อมูลตัวอย่าง 100 รายการสำเร็จ'),
              backgroundColor: context.colors.primaryBtn),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: context.colors.errorBg),
        );
      }
    }
  }

  Future<void> _clearData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        title: Text('ยืนยันล้างข้อมูล', style: TextStyle(color: context.colors.textNormal)),
        content: Text('การกระทำนี้จะลบข้อมูลที่บันทึกไว้ทั้งหมด คุณแน่ใจหรือไม่?', style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.errorText,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ล้างข้อมูล'),
          ),
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
            SnackBar(
                content: const Text('ล้างข้อมูลทั้งหมดสำเร็จ'),
                backgroundColor: context.colors.primaryBtn),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'),
                backgroundColor: context.colors.errorText),
          );
        }
      }
    }
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
          color: context.colors.textNormal,
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
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.borderColor),
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
                  fontSize: 14, color: cs.onSurface.withValues(alpha: 0.7))),
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

class _ActionRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  const _ActionRow({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDestructive ? context.colors.errorText : context.colors.textNormal,
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, size: 20, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }
}
