import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:soil_sensor/main.dart';
import 'package:soil_sensor/services/ble_service.dart';
import 'package:soil_sensor/services/wifi_service.dart';
import 'package:soil_sensor/providers/measurements_provider.dart';
import 'package:soil_sensor/providers/theme_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BleService()),
          ChangeNotifierProvider(create: (_) => WiFiService()),
          ChangeNotifierProvider(create: (_) => MeasurementsProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const SoilSensorApp(),
      ),
    );

    // Verify app renders bottom navigation
    expect(find.text('แดชบอร์ด'), findsOneWidget);
    expect(find.text('สแกน'), findsOneWidget);
    expect(find.text('ประวัติ'), findsOneWidget);
  });
}
