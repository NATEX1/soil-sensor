import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/ble_service.dart';

const _green600 = Color(0xFF16a34a);

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleService>();
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final headerBg = isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
    final headerSubtitle =
        isDark ? const Color(0xFF6b7280) : const Color(0xFFbbf7d0);
    final primaryBtn =
        isDark ? const Color(0xFF16a34a) : const Color(0xFF16a34a);
    final stopBtn = const Color(0xFFef4444);
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
    final textLabel =
        isDark ? const Color(0xFFd1d5db) : const Color(0xFF4b5563);
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final iconMuted =
        isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            color: headerBg,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 20),
            child: Row(
              children: [
                Icon(Icons.bluetooth_searching,
                    color: isDark ? const Color(0xFF4ade80) : Colors.white,
                    size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สแกน BLE',
                        style: TextStyle(
                            color:
                                isDark ? const Color(0xFFf9fafb) : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('ค้นหาอุปกรณ์ SoilSensor',
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
                if (ble.error != null) _ErrorBanner(message: ble.error!),

                if (ble.isConnected && ble.connectedDevice != null)
                  _ConnectedBanner(
                    name: ble.connectedDevice!.platformName.isNotEmpty
                        ? ble.connectedDevice!.platformName
                        : 'SoilSensor',
                    id: ble.connectedDevice!.remoteId.toString(),
                  ),

                const SizedBox(height: 16),

                // Scan animation + button
                Center(
                  child: Column(
                    children: [
                      _ScanAnimation(isScanning: ble.isScanning),
                      const SizedBox(height: 20),
                      Text(
                        ble.isScanning
                            ? 'กำลังสแกนหาอุปกรณ์...'
                            : 'กดปุ่มเพื่อเริ่มสแกน',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: ble.isScanning
                            ? () => context.read<BleService>().stopScan()
                            : () => context.read<BleService>().startScan(),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              ble.isScanning ? stopBtn : primaryBtn,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: const StadiumBorder(),
                        ),
                        icon: Icon(ble.isScanning ? Icons.stop : Icons.search,
                            size: 18),
                        label: Text(ble.isScanning ? 'หยุดสแกน' : 'เริ่มสแกน',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                if (ble.foundDevices.isNotEmpty) ...[
                  Text('พบอุปกรณ์ ${ble.foundDevices.length} เครื่อง',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textLabel)),
                  const SizedBox(height: 8),
                  ...ble.foundDevices.map((device) => _DeviceCard(
                        device: device,
                        isConnected:
                            ble.connectedDevice?.remoteId == device.remoteId,
                        onConnect: () async {
                          try {
                            await context.read<BleService>().connect(device);
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('เชื่อมต่อสำเร็จ'),
                                  content: Text(
                                      'เชื่อมต่อกับ ${device.platformName.isNotEmpty ? device.platformName : "อุปกรณ์"} เรียบร้อยแล้ว'),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          context.go('/');
                                        },
                                        child: const Text('ไปแดชบอร์ด')),
                                    TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('อยู่หน้านี้')),
                                  ],
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่'),
                                    backgroundColor: Color(0xFFef4444)),
                              );
                            }
                          }
                        },
                      )),
                ],

                const SizedBox(height: 16),
                _WarningBox(
                    text:
                        'ต้องเปิด Bluetooth และอนุญาตสิทธิ์ Location บนอุปกรณ์'),
              ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBtn = const Color(0xFF16a34a);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final iconMuted =
        isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);

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
                  color: isDark
                      ? const Color(0xFF15803d)
                          .withOpacity(0.15 * (2 - _animation.value))
                      : const Color(0xFF16a34a)
                          .withOpacity(0.15 * (2 - _animation.value)),
                ),
              ),
            ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isScanning ? primaryBtn : borderColor,
            ),
            child: Icon(Icons.bluetooth,
                color: widget.isScanning ? Colors.white : iconMuted, size: 32),
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
      {required this.device,
      required this.isConnected,
      required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1f2937) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
    final primaryBtn = const Color(0xFF16a34a);
    final iconMuted =
        isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final textMuted =
        isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isConnected ? const Color(0xFF86efac) : borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isConnected
                  ? (isDark ? const Color(0xFF052e16) : const Color(0xFFf0fdf4))
                  : (isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFf3f4f6)),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bluetooth,
                color: isConnected ? primaryBtn : iconMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.platformName.isNotEmpty
                      ? device.platformName
                      : 'Unknown Device',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFf3f4f6)
                          : const Color(0xFF1f2937)),
                ),
                Text(device.remoteId.toString(),
                    style: TextStyle(fontSize: 11, color: textMuted)),
              ],
            ),
          ),
          if (isConnected)
            Chip(
              label: Text('เชื่อมต่อแล้ว',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF86efac)
                        : const Color(0xFF15803d),
                  )),
              backgroundColor:
                  isDark ? const Color(0xFF052e16) : const Color(0xFFf0fdf4),
              side: const BorderSide(color: Color(0xFF86efac)),
              padding: EdgeInsets.zero,
            )
          else
            FilledButton(
              onPressed: onConnect,
              style: FilledButton.styleFrom(
                backgroundColor: primaryBtn,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
          border: Border.all(color: border)),
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF450a0a) : const Color(0xFFfef2f2);
    final border = isDark ? const Color(0xFF991b1b) : const Color(0xFFfecaca);
    final textColor =
        isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: textColor, fontSize: 13))),
        ],
      ),
    );
  }
}

class _ConnectedBanner extends StatelessWidget {
  final String name;
  final String id;
  const _ConnectedBanner({required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF052e16) : const Color(0xFFf0fdf4);
    final border = isDark ? const Color(0xFF16a34a) : const Color(0xFF86efac);
    final textColor =
        isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text('เชื่อมต่อกับ $name แล้ว',
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(id, style: TextStyle(color: textColor, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
