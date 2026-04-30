import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/wifi_service.dart';
import '../services/database_service.dart';
import '../providers/measurements_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final wifi = context.watch<WiFiService>();
    final themeProvider = context.watch<ThemeProvider>();
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final isAnyConnected = ble.isConnected || wifi.isConnected;
    
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, bottomPadding + 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ตั้งค่า',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textNormal,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 2),
                  Text('จัดการระบบแอปพลิเคชัน',
                      style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAnyConnected
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
                        color: isAnyConnected
                            ? context.colors.statusDotConnected
                            : context.colors.statusDotDisconnected,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isAnyConnected ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAnyConnected
                            ? context.colors.statusTextConnected
                            : context.colors.statusTextDisconnected,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Group 1: General Settings
          _SettingsGroup(
            items: [
              _SettingsItem(
                icon: Icons.wifi_rounded,
                iconColor: wifi.isConnected ? context.colors.primaryBtn : context.colors.textNormal,
                label: 'การเชื่อมต่อ Wi-Fi',
                subtitle: wifi.isConnected ? (wifi.deviceIp ?? 'ออนไลน์') : null,
                trailingText: !wifi.isConnected ? 'ไม่ได้เชื่อมต่อ' : null,
                trailingWidget: wifi.isConnected ? _buildDisconnectButton(context, () => _confirmWifiDisconnect(context, wifi)) : null,
              ),
              _SettingsItem(
                icon: Icons.bluetooth_rounded,
                iconColor: ble.isConnected ? context.colors.primaryBtn : context.colors.textNormal,
                label: 'การเชื่อมต่อ Bluetooth',
                subtitle: ble.isConnected 
                    ? (ble.isDemoMode ? 'โหมดจำลอง (Demo)' : 'MAC: ${ble.connectedDevice?.remoteId.str ?? 'ไม่ทราบข้อมูล'}') 
                    : null,
                trailingText: !ble.isConnected ? 'ไม่ได้เชื่อมต่อ' : null,
                trailingWidget: ble.isConnected ? _buildDisconnectButton(context, () => _confirmDisconnect(context, ble)) : null,
              ),
              _SettingsItem(
                icon: Icons.grass_rounded,
                label: 'จัดการชนิดพืช',
                onTap: () => context.push('/settings/plants'),
              ),
              _SettingsItem(
                icon: Icons.dark_mode_rounded,
                label: 'โหมดกลางคืน (Dark mode)',
                trailingWidget: CupertinoSwitch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeTrackColor: context.colors.primaryBtn,
                  inactiveTrackColor: context.colors.borderColor.withValues(alpha: 0.5),
                ),
                onTap: () => themeProvider.toggleTheme(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Group 2: System Info & Destructive Actions
          _SettingsGroup(
            items: [
              _SettingsItem(
                icon: Icons.info_outline_rounded,
                label: 'เกี่ยวกับแอปพลิเคชัน',
                trailingText: '1.0.0',
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เวอร์ชันปัจจุบัน: 1.0.0')));
                },
              ),
              _SettingsItem(
                icon: Icons.help_outline_rounded,
                label: 'คู่มือการใช้งาน',
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อยู่ระหว่างการจัดทำคู่มือ')));
                },
              ),
              _SettingsItem(
                icon: Icons.delete_outline_rounded,
                label: 'ล้างข้อมูลประวัติการวัดทั้งหมด',
                isDestructive: true,
                onTap: () => _clearData(context),
              ),
              _SettingsItem(
                icon: Icons.bug_report_outlined,
                label: 'สร้างข้อมูลทดสอบ (100 รายการ)',
                onTap: () async {
                  await DatabaseService.seedDummyData(count: 100);
                  final db = await DatabaseService.database;
                  final res = await db.rawQuery('SELECT COUNT(*) as count FROM measurements');
                  final total = (res.first['count'] as int?) ?? 0;
                  if (context.mounted) {
                    context.read<MeasurementsProvider>().fetch();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('สร้างข้อมูลสำเร็จ! ตอนนี้มีทั้งหมด $total รายการ'))
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton(BuildContext context, VoidCallback onPressed) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          foregroundColor: Colors.red.shade700,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.link_off_rounded, size: 14),
        label: const Text('ตัดการเชื่อมต่อ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmDisconnect(BuildContext context, BleService ble) {
    _showConfirm(context, 'Bluetooth', () => ble.disconnect());
  }

  void _confirmWifiDisconnect(BuildContext context, WiFiService wifi) {
    _showConfirm(context, 'Wi-Fi', () => wifi.disconnect());
  }

  void _showConfirm(BuildContext context, String title, Future<void> Function() onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยุติการเชื่อมต่อ $title', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textNormal)),
        content: Text('คุณต้องการตัดการเชื่อมต่อจากอุปกรณ์พกพาใช่หรือไม่?', style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async { Navigator.pop(ctx); await onConfirm(); },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ล้างข้อมูล', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.textNormal)),
        content: Text('ข้อมูลประวัติทั้งหมดจะถูกลบถาวร', style: TextStyle(color: context.colors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('ยกเลิก', style: TextStyle(color: context.colors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('ลบข้อมูล'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final db = await DatabaseService.database;
      await db.delete('measurements');
      if (!context.mounted) return;
      context.read<MeasurementsProvider>().fetch();
    }
  }
}

// ----------------------------------------------------
// UI Components closely mimicking the Dashboard design
// ----------------------------------------------------

class _SettingsGroup extends StatelessWidget {
  final List<Widget> items;

  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.borderColor),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(
                height: 1, 
                indent: 0, // 20 padding + 24 icon + 20 spacing
                endIndent: 0, 
                color: context.colors.dividerColor.withValues(alpha: 0.6)
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool isDestructive;
  final Color? iconColor;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.onTap,
    this.isDestructive = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? Colors.red.shade400 : context.colors.textNormal;
    final finalIconColor = iconColor ?? (isDestructive ? Colors.red.shade400 : context.colors.textNormal);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: finalIconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
                  ]
                ],
              ),
            ),
            if (trailingText != null)
              Text(trailingText!, style: TextStyle(fontSize: 14, color: context.colors.textMuted)),
            if (trailingText != null) const SizedBox(width: 8),
            
            // Only show chevron if there is no explicit trailing widget AND it is tappable
            if (trailingWidget != null)
              trailingWidget!
            else if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: context.colors.iconMuted),
          ],
        ),
      ),
    );
  }
}
