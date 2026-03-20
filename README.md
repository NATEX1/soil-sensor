# SoilSensor Flutter

ระบบวิเคราะห์ดินอัจฉริยะ — migrated จาก React Native / Expo SDK 54

## โครงสร้างโปรเจกต์

```
lib/
├── main.dart                    # Entry point + GoRouter navigation
├── env.dart                     # Environment config
├── models/
│   ├── sensor_data.dart         # SensorData, MeasurementRecord, enums
│   └── calculations.dart        # Thresholds, getSoilStatus, recommendations
├── services/
│   ├── ble_service.dart         # BLE (flutter_blue_plus) — ChangeNotifier
│   └── supabase_service.dart    # Supabase CRUD
├── providers/
│   └── measurements_provider.dart  # History state + date range filter
├── screens/
│   ├── dashboard_screen.dart    # Tab 1: แดชบอร์ด
│   ├── scan_screen.dart         # Tab 2: สแกน BLE
│   ├── history_screen.dart      # Tab 3: ประวัติ + กราฟ
│   ├── map_screen.dart          # Tab 4: แผนที่
│   ├── settings_screen.dart     # Tab 5: ตั้งค่า
│   └── recommend_screen.dart    # Modal: คำแนะนำ
└── widgets/
    ├── sensor_card.dart         # SensorCard widget
    ├── soil_chart.dart          # Line chart (fl_chart)
    └── save_modal.dart          # Bottom sheet บันทึกผล
```

## Dependencies หลัก

| Package | ใช้แทน |
|---------|--------|
| `go_router` | expo-router |
| `supabase_flutter` | @supabase/supabase-js |
| `flutter_blue_plus` | react-native-ble-plx |
| `google_maps_flutter` | react-native-maps |
| `geolocator` | expo-location |
| `fl_chart` | SoilChart (custom) |
| `provider` | React Context / hooks |
| `excel` + `share_plus` | expo-file-system + expo-sharing |

## การติดตั้ง

```bash
flutter pub get
```

## การรัน

```bash
# ใส่ Supabase credentials
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## Android Permissions

เพิ่มใน `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## iOS Permissions

เพิ่มใน `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>ใช้ Bluetooth เพื่อเชื่อมต่อกับ SoilSensor</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>ใช้ตำแหน่งเพื่อบันทึกพิกัดจุดเก็บตัวอย่าง</string>
```

## Google Maps API Key

เพิ่มใน `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>
```

เพิ่มใน `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

## BLE Protocol

เหมือนเดิม — ESP32 ส่ง JSON ผ่าน BLE characteristic:

```json
{"ph": 6.8, "n": 142, "p": 38, "k": 210, "moisture": 45.2, "temp": 28.5, "ec": 1.2}
```

- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **Characteristic UUID**: `abcd1234-ab12-ab12-ab12-abcdef123456`
- **Device Name**: `SoilSensor`
