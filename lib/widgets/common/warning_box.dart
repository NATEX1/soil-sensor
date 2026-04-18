import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WarningBox extends StatelessWidget {
  final String title;
  final String content;

  const WarningBox({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: context.colors.warningText),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.colors.warningText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              color: context.colors.warningText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
