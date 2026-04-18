import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';
import '../theme/app_colors.dart';
import '../widgets/common/warning_box.dart';
import '../widgets/common/status_banners.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
        children: [
          // — Minimal Header —
          Text('สแกน BLE',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textNormal,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text('ค้นหาอุปกรณ์ SoilSensor',
              style: TextStyle(fontSize: 13, color: context.colors.textMuted)),

          const SizedBox(height: 20),

          if (ble.error != null) ErrorBanner(message: ble.error!),
          if (ble.isConnected && ble.connectedDevice != null && !ble.isDemoMode)
            ConnectedBanner(
              name: ble.connectedDevice!.platformName.isNotEmpty
                  ? ble.connectedDevice!.platformName
                  : 'SoilSensor',
              id: ble.connectedDevice!.remoteId.toString(),
            ),
          if (ble.isDemoMode)
            const ConnectedBanner(name: 'Demo Sensor', id: 'Simulator'),

          const SizedBox(height: 24),

          // — Scan animation + button —
          Center(
            child: Column(
              children: [
                _ScanAnimation(isScanning: ble.isScanning),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    ble.isScanning ? 'กำลังค้นหา...' : 'พร้อมเริ่มการค้นหา',
                    key: ValueKey(ble.isScanning),
                    style: TextStyle(color: context.colors.textMuted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: ble.isScanning
                      ? () => context.read<BleService>().stopScan()
                      : () => context.read<BleService>().startScan(),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        ble.isScanning ? context.colors.errorBg : context.colors.primaryBtn,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  icon: Icon(ble.isScanning ? Icons.stop : Icons.search, size: 18),
                  label: Text(ble.isScanning ? 'หยุดสแกน' : 'เริ่มสแกน',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // — Found devices —
          if (ble.foundDevices.isNotEmpty) ...[
            Text('พบ ${ble.foundDevices.length} อุปกรณ์',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textNormal)),
            const SizedBox(height: 10),
            ...ble.foundDevices.map((device) => _DeviceCard(
                  device: device,
                  isConnected: ble.connectedDevice?.remoteId == device.remoteId,
                  onConnect: () async {
                    try {
                      await context.read<BleService>().connect(device);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('เชื่อมต่อสำเร็จ'),
                            content: Text(
                                'เชื่อมต่อกับ ${device.platformName.isNotEmpty ? device.platformName : "อุปกรณ์"} เรียบร้อยแล้ว'),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                    Future.microtask(() {
                                      if (context.mounted) context.go('/');
                                    });
                                  },
                                  child: const Text('ไปแดชบอร์ด')),
                              TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('อยู่หน้านี้')),
                            ],
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่'),
                              backgroundColor: Color(0xFFef4444)),
                        );
                      }
                    }
                  },
                )),
          ],

          const SizedBox(height: 20),
          const WarningBox(
            title: 'หมายเหตุ',
            content: 'ต้องเปิด Bluetooth และอนุญาตสิทธิ์ Location บนอุปกรณ์',
          ),

          const SizedBox(height: 16),

          if (!ble.isConnected)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  context.read<BleService>().startDemoMode();
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('โหมดจำลอง'),
                        content: const Text('จำลองข้อมูลเซ็นเซอร์โดยไม่ต้องใช้อุปกรณ์จริง'),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Future.microtask(() {
                                  if (context.mounted) context.go('/');
                                });
                              },
                              child: const Text('ไปแดชบอร์ด')),
                          TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('ปิด')),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.science_outlined, size: 16),
                label: Text('ทดสอบด้วย Demo Mode',
                    style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanAnimation extends StatefulWidget {
  final bool isScanning;
  const _ScanAnimation({required this.isScanning});
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
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
            child: Icon(Icons.bluetooth,
                color: widget.isScanning ? Colors.white : context.colors.textMuted,
                size: 30),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final dynamic device;
  final bool isConnected;
  final VoidCallback onConnect;

  const _DeviceCard(
      {required this.device, required this.isConnected, required this.onConnect});

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
                color: isConnected ? context.colors.primaryBtn : context.colors.textMuted,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.platformName.isNotEmpty ? device.platformName : 'Unknown',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: context.colors.textNormal),
                ),
                Text(device.remoteId.toString(),
                    style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
              ],
            ),
          ),
          if (isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.successBannerBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('เชื่อมต่อแล้ว',
                  style: TextStyle(fontSize: 11, color: context.colors.successBannerText)),
            )
          else
            FilledButton(
              onPressed: onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primaryBtn,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('เชื่อมต่อ', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
