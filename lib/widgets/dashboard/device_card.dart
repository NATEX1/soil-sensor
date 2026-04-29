import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DeviceCard extends StatelessWidget {
  final dynamic device;
  final bool isConnected;
  final VoidCallback onConnect;

  const DeviceCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onConnect,
  });

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
