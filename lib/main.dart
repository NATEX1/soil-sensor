import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/ble_service.dart';
import 'services/wifi_service.dart';
import 'providers/measurements_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/plot_provider.dart';
import 'screens/dashboard_screen.dart';

import 'screens/history_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/settings/plants_management_screen.dart';
import 'models/sensor_data.dart';
import 'models/calculations.dart';
import 'screens/cassava_fertilizer_screen.dart';
import 'screens/splash_screen.dart';

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
        ChangeNotifierProvider(create: (_) => PlotProvider()),
      ],
      child: const SoilavaApp(),
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
  initialLocation: '/splash',
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
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/recommend',
      pageBuilder: (_, state) => _slidePage(
        RecommendScreen(plot: state.extra as PlotRecord?),
        state,
      ),
    ),
    GoRoute(
      path: '/settings/plants',
      pageBuilder: (_, state) => _slidePage(const PlantsManagementScreen(), state),
    ),
    GoRoute(
      path: '/cassava-fertilizer',
      pageBuilder: (_, state) {
        final args = state.extra as Map<String, dynamic>;
        return _slidePage(
          CassavaFertilizerScreen(
            plot: args['plot'] as PlotRecord,
            variety: args['variety'] as CassavaVariety,
          ),
          state,
        );
      },
    ),
  ],
);

class SoilavaApp extends StatelessWidget {
  const SoilavaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    final baseTextTheme = GoogleFonts.promptTextTheme();

    return MaterialApp.router(
      title: 'Soilava',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16a34a),
          primary: const Color(0xFF16a34a),
          surface: const Color(0xFFffffff),
          onSurface: const Color(0xFF09090b),
          outline: const Color(0xFFe4e4e7),
        ),
        useMaterial3: true,
        textTheme: baseTextTheme,
        scaffoldBackgroundColor: const Color(0xFFffffff),
        cardColor: const Color(0xFFffffff),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFFe4e4e7), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF16a34a),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF09090b),
            side: const BorderSide(color: Color(0xFFe4e4e7)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe4e4e7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFe4e4e7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFe4e4e7),
          thickness: 1,
          space: 1,
        ),
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
          primary: Color(0xFF16a34a),
          onPrimary: Colors.white,
          secondary: Color(0xFF16a34a),
          surface: Color(0xFF09090b),
          onSurface: Color(0xFFfafafa),
          error: Color(0xFF450a0a),
          onError: Color(0xFFf87171),
          outline: Color(0xFF27272a),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.promptTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF09090b),
        cardColor: const Color(0xFF09090b),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Color(0xFF09090b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: Color(0xFF27272a), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF16a34a),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFfafafa),
            side: const BorderSide(color: Color(0xFF27272a)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF27272a)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF27272a)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF16a34a), width: 2),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF27272a),
          thickness: 1,
          space: 1,
        ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF09090b) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF27272a) : const Color(0xFFe4e4e7),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: isDark ? const Color(0xFF16a34a) : const Color(0xFF16a34a),
              unselectedItemColor: isDark ? const Color(0xFF71717a) : const Color(0xFFa1a1aa),
              selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
              unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.eco_outlined, size: 24)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.eco_rounded, size: 24)),
                  label: 'แดชบอร์ด',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.bar_chart_outlined, size: 24)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.bar_chart_rounded, size: 24)),
                  label: 'ประวัติ',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.map_outlined, size: 24)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.map_rounded, size: 24)),
                  label: 'แผนที่',
                ),
                BottomNavigationBarItem(
                  icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.settings_outlined, size: 24)),
                  activeIcon: Padding(padding: EdgeInsets.only(bottom: 4, top: 4), child: Icon(Icons.settings_rounded, size: 24)),
                  label: 'ตั้งค่า',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
