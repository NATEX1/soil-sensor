import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/ble_service.dart';
import 'services/wifi_service.dart';
import 'providers/measurements_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';

import 'screens/history_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/settings/plants_management_screen.dart';
import 'models/sensor_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleService()),
        ChangeNotifierProvider(create: (_) => WiFiService()),
        ChangeNotifierProvider(create: (_) => MeasurementsProvider()..fetch()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const SoilSensorApp(),
    ),
  );
}

// Slide transition for sub-pages (from Right to Left)
CustomTransitionPage<void> _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen())
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen())
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/map', builder: (_, __) => const MapScreen())
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen())
        ]),
      ],
    ),
    GoRoute(
      path: '/recommend',
      pageBuilder: (_, state) => _slidePage(
        RecommendScreen(record: state.extra as MeasurementRecord?),
        state,
      ),
    ),
    GoRoute(
      path: '/settings/plants',
      pageBuilder: (_, state) => _slidePage(const PlantsManagementScreen(), state),
    ),
  ],
);

class SoilSensorApp extends StatelessWidget {
  const SoilSensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'SoilSensor',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16a34a)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFf9fafb),
        cardColor: Colors.white,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF15803d),
          onPrimary: Colors.white,
          secondary: Color(0xFF16a34a),
          surface: Color(0xFF1f2937),
          onSurface: Color(0xFFf3f4f6),
          error: Color(0xFFef4444),
          onError: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF111827),
        cardColor: const Color(0xFF1f2937),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: _router,
    );
  }
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: isDark ? const Color(0xFF1f2937) : Colors.white,
        indicatorColor: isDark ? const Color(0xFF14532d) : const Color(0xFFdcfce7),
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.eco_outlined,
                color: isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af)),
            selectedIcon: Icon(Icons.eco,
                color: isDark ? Colors.white : const Color(0xFF16a34a)),
            label: 'แดชบอร์ด',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined,
                color: isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af)),
            selectedIcon: Icon(Icons.bar_chart,
                color: isDark ? Colors.white : const Color(0xFF16a34a)),
            label: 'ประวัติ',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined,
                color: isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af)),
            selectedIcon: Icon(Icons.map,
                color: isDark ? Colors.white : const Color(0xFF16a34a)),
            label: 'แผนที่',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined,
                color: isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af)),
            selectedIcon: Icon(Icons.settings,
                color: isDark ? Colors.white : const Color(0xFF16a34a)),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}
