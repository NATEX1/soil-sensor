import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  // Backgrounds
  Color get headerBg => isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);
  Color get headerSubtitle => isDark ? const Color(0xFF6b7280) : const Color(0xFFbbf7d0);
  Color get headerIcon => isDark ? const Color(0xFF4ade80) : const Color(0xFFbbf7d0);
  Color get cardBg => isDark ? const Color(0xFF1f2937) : Colors.white;
  Color get bgAlt => isDark ? const Color(0xFF111827) : const Color(0xFFf9fafb);

  // Borders & Dividers
  Color get borderColor => isDark ? const Color(0xFF374151) : const Color(0xFFe5e7eb);
  Color get dividerColor => isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6);

  // Typography
  Color get textNormal => isDark ? const Color(0xFFe5e7eb) : const Color(0xFF374151);
  Color get textLabel => isDark ? const Color(0xFFd1d5db) : const Color(0xFF4b5563);
  Color get textMuted => isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);
  Color get iconMuted => isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);

  // Buttons & Interactive
  Color get primaryBtn => isDark ? const Color(0xFF15803d) : const Color(0xFF16a34a);
  Color get outlineBtn => isDark ? const Color(0xFF16a34a) : const Color(0xFF16a34a);
  Color get scaffoldBg => isDark ? const Color(0xFF111827) : const Color(0xFFf3f4f6);
  Color get appBarBg => isDark ? const Color(0xFF1f2937) : const Color(0xFF16a34a);

  // Warning state
  Color get warningBg => isDark ? const Color(0xFF422006) : const Color(0xFFfffbeb);
  Color get warningBorder => isDark ? const Color(0xFF92400e) : const Color(0xFFfde68a);
  Color get warningText => const Color(0xFFfbbf24);
  Color get warningOrange => isDark ? const Color(0xFFfbbf24) : const Color(0xFFf97316);

  // Error state
  Color get errorBg => isDark ? const Color(0xFF450a0a) : const Color(0xFFfef2f2);
  Color get errorBorder => isDark ? const Color(0xFF991b1b) : const Color(0xFFfecaca);
  Color get errorText => isDark ? const Color(0xFFfca5a5) : const Color(0xFFb91c1c);

  // Success state (Banner)
  Color get successBannerBg => isDark ? const Color(0xFF052e16) : const Color(0xFFf0fdf4);
  Color get successBannerBorder => isDark ? const Color(0xFF16a34a) : const Color(0xFF86efac);
  Color get successBannerText => isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);

  // BLE Connectivity states
  Color get statusConnectedBg => isDark ? const Color(0xFF052e16) : const Color(0xFFdcfce7);
  Color get statusDisconnectedBg => isDark ? const Color(0xFF374151) : const Color(0xFFf3f4f6);
  Color get statusDotConnected => const Color(0xFF22c55e);
  Color get statusDotDisconnected => isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
  Color get statusTextConnected => isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);
  Color get statusTextDisconnected => isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280);

  // Dashboard specific
  Color get statusDotDashboardConnected => isDark ? const Color(0xFF86efac) : const Color(0xFFbbf7d0);
  Color get statusDotDashboardDisconnected => isDark ? const Color(0xFFfca5a5) : const Color(0xFFfecaca);
  Color get statusDashboardConnectedBg => const Color(0xFF22c55e);
  Color get statusDashboardDisconnectedBg => const Color(0xFFef4444);

  // Map & Tabs
  Color get tabBg => isDark ? const Color(0xFF1f2937) : const Color(0xFFf3f4f6);
  Color get tabSelectedBg => isDark ? const Color(0xFF374151) : Colors.white;
  Color get tabSelected => isDark ? const Color(0xFF22c55e) : const Color(0xFF16a34a);
  Color get mapDragHandle => isDark ? const Color(0xFF6b7280) : const Color(0xFFd1d5db);
  Color get mapSelectedBorder => isDark ? const Color(0xFF16a34a) : const Color(0xFF86efac);
  Color get phColor => isDark ? const Color(0xFF86efac) : const Color(0xFF15803d);

  // Brand
  Color get switchColor => isDark ? const Color(0xFF22c55e) : const Color(0xFF16a34a);
  Color get green600 => const Color(0xFF16a34a);
  Color get mapPrimary => isDark ? const Color(0xFF15803d) : const Color(0xFF16a34a);
}

extension AppThemeContext on BuildContext {
  AppColors get colors => AppColors(Theme.of(this).brightness == Brightness.dark);
}
