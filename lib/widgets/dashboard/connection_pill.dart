import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../screens/dashboard_screen.dart'; // for ConnectionMode

class ConnectionPill extends StatelessWidget {
  final bool isConnected;
  final ConnectionMode mode;
  const ConnectionPill({super.key, required this.isConnected, required this.mode});

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
