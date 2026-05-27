import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;
  const AppColors(this.isDark);

  // Backgrounds
  Color get scaffoldBg => isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF);
  Color get cardBg => isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF);
  Color get bgAlt => isDark ? const Color(0xFF262626) : const Color(0xFFFAFAFA);
  
  // Headers
  Color get headerBg => isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF);
  Color get headerSubtitle => isDark ? const Color(0xFFA3A3A3) : const Color(0xFF737373);
  Color get headerIcon => const Color(0xFF16A34A);
  
  // Borders & Dividers
  Color get borderColor => isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);
  Color get dividerColor => isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7);

  // Typography
  Color get textNormal => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
  Color get textLabel => isDark ? const Color(0xFFD4D4D4) : const Color(0xFF404040);
  Color get textMuted => isDark ? const Color(0xFFA3A3A3) : const Color(0xFF737373);
  Color get iconMuted => isDark ? const Color(0xFFA3A3A3) : const Color(0xFF737373);

  // Buttons & Interactive
  Color get primaryBtn => const Color(0xFF16A34A);
  Color get outlineBtn => isDark ? const Color(0xFF404040) : const Color(0xFF171717);
  Color get appBarBg => isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF);

  // Warning state
  Color get warningBg => isDark ? const Color(0xFF422006) : const Color(0xFFFFFBEB);
  Color get warningBorder => isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A);
  Color get warningText => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get warningOrange => isDark ? const Color(0xFFFBBF24) : const Color(0xFFF97316);

  // Error state
  Color get errorBg => isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2);
  Color get errorBorder => isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
  Color get errorText => isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);

  // Success state (Banner)
  Color get successBannerBg => isDark ? const Color(0xFF052E16) : const Color(0xFFF0FDF4);
  Color get successBannerBorder => isDark ? const Color(0xFF16A34A) : const Color(0xFF86EFAC);
  Color get successBannerText => isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);

  // BLE Connectivity states
  Color get statusConnectedBg => isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
  Color get statusDisconnectedBg => isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
  Color get statusDotConnected => const Color(0xFF22C55E);
  Color get statusDotDisconnected => isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
  Color get statusTextConnected => isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);
  Color get statusTextDisconnected => isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

  // Dashboard specific
  Color get statusDotDashboardConnected => isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
  Color get statusDotDashboardDisconnected => isDark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
  Color get statusDashboardConnectedBg => const Color(0xFF22C55E);
  Color get statusDashboardDisconnectedBg => const Color(0xFFEF4444);

  // Map & Tabs
  Color get tabBg => isDark ? const Color(0xFF171717) : const Color(0xFFFFFFFF);
  Color get tabSelectedBg => isDark ? const Color(0xFF262626) : const Color(0xFF171717);
  Color get tabSelected => isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF); // Selected tab text is white in light mode because bg is #171717
  Color get mapDragHandle => isDark ? const Color(0xFF71717A) : const Color(0xFFD4D4D8);
  Color get mapSelectedBorder => const Color(0xFF16A34A);
  Color get phColor => isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);

  // Brand
  Color get switchColor => const Color(0xFF16A34A);
  Color get green600 => const Color(0xFF16A34A);
  Color get mapPrimary => const Color(0xFF16A34A);
}

extension AppThemeContext on BuildContext {
  AppColors get colors => AppColors(Theme.of(this).brightness == Brightness.dark);
}
