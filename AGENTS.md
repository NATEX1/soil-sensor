# AGENTS.md - SoilSensor Flutter Development Guide

## Project Overview

**SoilSensor Flutter** - Smart soil analysis mobile app (iOS/Android) migrated from React Native.
Uses Provider for state management, GoRouter for navigation, and SQLite (sqflite) for local storage.

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run development (no Supabase needed - uses local SQLite)
flutter run

# Analyze/lint code
flutter analyze

# Run all tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Build release
flutter build apk --release        # Android
flutter build ios --release        # iOS

# Build with specific target
flutter build ios --simulator --no-codesign
```

## Code Style Guidelines

### General Rules
- Uses Flutter recommended lints (`package:flutter_lints/flutter.yaml`)
- All lints enabled by default - do not disable unless absolutely necessary
- Run `flutter analyze` before committing

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `BleService`, `SensorData` |
| Enums | PascalCase | `SoilStatus`, `PlantType` |
| Methods/variables | camelCase | `startScan()`, `isConnected` |
| Private members | prefix `_` | `_scanResults`, `_connect()` |
| Constants (file-level) | camelCase | `plantTypeLabels`, `sampleMethodValues` |
| File names | snake_case | `sensor_data.dart`, `ble_service.dart` |
| Map keys (API) | snake_case | `'plant_type'`, `'measured_at'` |

### File Organization
- One primary class per file (exceptions for small helper classes like `_StatusConfig`)
- Private classes prefixed with `_`
- Group related items together (enums, const maps, then main class)

### Imports
```dart
// Package imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Relative imports within lib/
import '../models/sensor_data.dart';
import '../../services/database_service.dart';

// DO NOT use barrel exports (index.dart) unless for public API
```

### Widget Patterns
- Use `StatelessWidget` for pure UI components
- Use `StatefulWidget` when needing local state
- Define theme-aware colors at top of `build()` method
- Extract reusable widgets to `lib/widgets/`

### State Management (Provider)
```dart
// Reading once (doesn't rebuild)
final service = context.read<BleService>();

// Watching for changes (rebuilds on change)
final isScanning = context.watch<BleService>().isScanning;

// Reading in build methods
Provider.of<BleService>(context, listen: false)

// Services should extend ChangeNotifier for reactive updates
```

### Error Handling
- Use `try-catch` with specific exception types when possible
- For async operations, handle errors and show user feedback via SnackBar
- Services should expose error states via ChangeNotifier properties
- Use `?` nullable operators to handle potentially null values

### Async/Await
```dart
// Preferred pattern
Future<void> fetchData() async {
  try {
    setState(() => _isLoading = true);
    final result = await databaseService.fetchRecords();
    // handle result
  } catch (e) {
    // handle error - show SnackBar or set error state
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Data Models
- Immutable classes use `const` constructor
- Use `final` for properties that don't change after construction
- JSON serialization with `fromJson` factory and `toJson` method
- Use enums for fixed sets of values (not strings)
- Create mapping dictionaries for enum <-> string conversion

### BLE Service Patterns
- Extend `ChangeNotifier` for reactive BLE state
- Handle permission requests before scanning
- Emit state changes via `notifyListeners()`
- Support both scanning and direct connection modes

## Architecture

```
lib/
├── main.dart                    # App entry + GoRouter setup
├── env.dart                     # Environment config (dart-define)
├── models/                      # Data models + business logic
├── services/                    # External integrations (BLE, Supabase, WiFi)
├── providers/                    # State management
├── screens/                     # Full-page views
├── widgets/                     # Reusable UI components
└── theme/                       # App theming
```

## BLE Protocol Reference
- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **Characteristic UUID**: `abcd1234-ab12-ab12-ab12-abcdef123456`
- **Device Name**: `SoilSensor`
- ESP32 sends JSON via BLE characteristic

## Key Dependencies
| Package | Purpose |
|---------|---------|
| `sqflite` | Local SQLite database |
| `provider` | State management |
| `go_router` | Navigation |
| `flutter_blue_plus` | BLE communication |
| `flutter_map` | Map display |
| `fl_chart` | Charts |
| `excel` | Excel export |

## Testing Guidelines
- Use `flutter_test` (default Flutter test package)
- Place tests in `test/` directory matching `lib/` structure
- Use `WidgetTester` for widget tests
- Mock external services (Database, BLE) when appropriate
- Current test coverage is minimal - expand as features are added

## Working with Enums

```dart
enum SoilStatus { low, normal, high }

// String mapping (for DB/API)
const Map<SoilStatus, String> soilStatusValues = {
  SoilStatus.low: 'low',
  SoilStatus.normal: 'normal',
  SoilStatus.high: 'high',
};

// Parser
SoilStatus statusFromString(String s) =>
    soilStatusValues.entries
        .firstWhere((e) => e.value == s, orElse: () => MapEntry(SoilStatus.normal, 'normal'))
        .key;
```

## Permissions Required

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS (Info.plist)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>ใช้ Bluetooth เพื่อเชื่อมต่อกับ SoilSensor</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>ใช้ตำแหน่งเพื่อบันทึกพิกัดจุดเก็บตัวอย่าง</string>
```

## Dashboard Requirements

**CRITICAL**: The dashboard MUST show soil stats WITHOUT requiring BLE connection.

Current behavior (WRONG): Shows "ยังไม่มีข้อมูลเซ็นเซอร์" when `ble.sensorData == null`
Required behavior: Show recent measurements from `MeasurementsProvider` (Supabase history) when not connected

Implementation approach:
- When `ble.isConnected == false` and `ble.sensorData == null`, display recent measurements from `context.watch<MeasurementsProvider>().filteredMeasurements`
- Show last saved measurement summary or "no saved measurements" state
- BLE-connected data should still take priority when available
- Use `MeasurementsProvider` which is already initialized in `main.dart` and fetches from Supabase

## Common Tasks

### Adding a new screen
1. Create file in `lib/screens/`
2. Register route in `main.dart` GoRouter config
3. Add navigation item if part of bottom nav

### Adding a new BLE feature
1. Update `lib/services/ble_service.dart`
2. Extend ChangeNotifier for state
3. Handle permissions in calling widget

### Adding a new model
1. Create file in `lib/models/`
2. Include enums, const maps, and main class
3. Add JSON serialization (`fromJson`, `toJson`)
4. Create parsing functions for enum conversions
