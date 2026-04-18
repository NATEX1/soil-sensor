import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.errorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: context.colors.errorText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: context.colors.errorText, fontSize: 13),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onRetry,
            child: Padding(
              padding: const EdgeInsets.only(top: 6, left: 24),
              child: Text(
                'ลองใหม่',
                style: TextStyle(
                  color: context.colors.errorText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
