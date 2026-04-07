import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/ble_service.dart';
import 'services/wifi_service.dart';
import 'providers/measurements_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recommend_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF16a34a),
    statusBarIconBrightness: Brightness.light,
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
          GoRoute(path: '/scan', builder: (_, __) => const ScanScreen())
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
    GoRoute(path: '/recommend', builder: (_, __) => const RecommendScreen()),
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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF16a34a),
                );
              }
              return IconThemeData(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF9ca3af)
                    : const Color(0xFF6b7280),
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1f2937)
              : Colors.white,
          indicatorColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF14532d)
              : const Color(0xFFdcfce7),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco),
                label: 'แดชบอร์ด'),
            NavigationDestination(
                icon: Icon(Icons.bluetooth_searching),
                selectedIcon: Icon(Icons.bluetooth_connected),
                label: 'สแกน'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'ประวัติ'),
            NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'แผนที่'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'ตั้งค่า'),
          ],
        ),
      ),
    );
  }
}
