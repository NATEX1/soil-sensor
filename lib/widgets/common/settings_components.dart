import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.colors.textMuted),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textNormal,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: context.colors.switchColor,
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String title;

  const SectionLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: context.colors.textMuted,
        ),
      ),
    );
  }
}
