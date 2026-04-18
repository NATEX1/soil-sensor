import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: context.colors.errorBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.errorBorder)),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: context.colors.errorText),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: context.colors.errorText, fontSize: 13))),
        ],
      ),
    );
  }
}

class ConnectedBanner extends StatelessWidget {
  final String name;
  final String id;
  const ConnectedBanner({super.key, required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: context.colors.successBannerBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.successBannerBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.check_circle, size: 16, color: context.colors.successBannerText),
            const SizedBox(width: 8),
            Text('เชื่อมต่อกับ $name แล้ว',
                style: TextStyle(
                    color: context.colors.successBannerText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(id, style: TextStyle(color: context.colors.successBannerText, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
