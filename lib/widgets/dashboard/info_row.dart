import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow({super.key, required this.icon, required this.label, required this.value});

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
