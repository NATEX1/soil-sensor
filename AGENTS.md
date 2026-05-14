# AGENTS.md - SoilSensor Flutter Development Guide

## Project Overview

**SoilSensor Flutter** — Smart soil analysis mobile app (iOS/Android).
Uses **Provider** for state management, **GoRouter** for navigation, and **SQLite (sqflite)** for local storage.
The app uses a **plot-based architecture** where multiple soil measurements are grouped into a "Plot" for aggregate analysis and tracking.
UI supports **light/dark mode** via `ThemeProvider` with a centralized color system (`AppColors`).

## Build Commands

```bash
# Install dependencies
flutter pub get

# Run development (uses local SQLite)
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
- All lints enabled by default — do not disable unless absolutely necessary
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
| Map keys (API/DB) | snake_case | `'plant_id'`, `'measured_at'` |

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
- Access theme colors via `context.colors` extension (from `AppColors`)
- Extract reusable widgets to `lib/widgets/` organized by feature subdirectory

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
    final result = await DatabaseService.getMeasurements();
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
├── main.dart                    # App entry, MultiProvider, GoRouter, MainShell
├── env.dart                     # Environment config (dart-define)
├── models/
│   ├── sensor_data.dart         # SensorData, MeasurementRecord, enums, plant maps
│   └── calculations.dart        # Thresholds, recommendations, soil status logic
├── services/
│   ├── ble_service.dart         # BLE scanning, connection, data parsing
│   ├── database_service.dart    # SQLite CRUD, migrations, seed data, plants table
│   ├── supabase_service.dart    # Cloud sync (legacy, not in active use)
│   ├── wifi_service.dart        # Wi-Fi/HTTP sensor communication
│   └── geocoding_service.dart   # Reverse geocoding with in-memory cache
├── providers/
│   ├── measurements_provider.dart  # Paginated plot data, date range filter, CRUD
│   ├── plot_provider.dart          # Active plot management, creation, and selection
│   └── theme_provider.dart         # Dark/light mode with SharedPreferences
├── screens/
│   ├── dashboard_screen.dart    # Main sensor dashboard
│   ├── history_screen.dart      # Measurement history with pagination
│   ├── map_screen.dart          # Map view of measurement locations
│   ├── recommend_screen.dart    # Soil improvement recommendations
│   ├── settings_screen.dart     # App settings & data management
│   └── settings/
│       └── plants_management_screen.dart  # Custom plant CRUD
├── widgets/
│   ├── common/
│   │   ├── error_card.dart          # Reusable error display card
│   │   ├── status_banners.dart      # Success/warning/error banners
│   │   ├── warning_box.dart         # Warning message box
│   │   └── settings_components.dart # Shared settings UI components
│   ├── dashboard/
│   │   ├── connection_pill.dart     # BLE connection status pill
│   │   ├── device_card.dart         # BLE device list card
│   │   ├── info_row.dart            # Key-value info row
│   │   ├── mode_tab.dart            # BLE/WiFi mode tab switcher
│   │   ├── save_modal.dart          # Save measurement modal
│   │   ├── scan_animation.dart      # BLE scan animation
│   │   └── sensor_card.dart         # Sensor reading card
│   ├── history/
│   │   └── history_list_view.dart   # History list with infinite scroll
│   └── map/
│       └── map_bottom_sheet.dart    # Map marker detail bottom sheet
└── theme/
    └── app_colors.dart          # Centralized color tokens + BuildContext extension
```

## Theme & Color System

Colors are centralized in `AppColors` (see `lib/theme/app_colors.dart`).
Access via the `BuildContext` extension:

```dart
final c = context.colors;

// Examples:
c.cardBg        // Card background (auto dark/light)
c.textNormal    // Primary text color
c.primaryBtn    // Primary button color
c.borderColor   // Border/divider color
c.warningBg     // Warning state background
c.errorText     // Error state text
```

**Rule**: Always use `context.colors` for colors that differ between light/dark mode. Do NOT hardcode hex values in widgets.

## Navigation (GoRouter)

Routes are defined in `main.dart` using `StatefulShellRoute.indexedStack` for the bottom nav tabs:

| Route | Screen | Tab |
|-------|--------|-----|
| `/` | `DashboardScreen` | แดชบอร์ด |
| `/history` | `HistoryScreen` | ประวัติ |
| `/map` | `MapScreen` | แผนที่ |
| `/settings` | `SettingsScreen` | ตั้งค่า |
| `/recommend` | `RecommendScreen` | — (slide transition, receives `PlotRecord` via `extra`) |
| `/settings/plants` | `PlantsManagementScreen` | — (slide transition) |

Sub-pages use `_slidePage()` for right-to-left slide transitions.

## Database Schema (SQLite)

### `plots` table (Main Entity)
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | Timestamp-based ID |
| `name` | TEXT | Plot name |
| `created_at` | TEXT | ISO 8601 |
| `notes` | TEXT | Optional |
| `lat`, `lng` | REAL | Optional center coordinates |

### `measurements` table
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | UUID |
| `plot_id` | TEXT | FK to `plots.id` (Replaces `user_id` / legacy schema) |
| `measured_at` | TEXT | ISO 8601 |
| `plant_id` | TEXT | FK to `plants.id` |
| `sample_method` | TEXT | `surface_0_15`, `deep_15_30`, `deep_30_60` |
| `notes` | TEXT | Optional |
| `point_name` | TEXT | Optional location label |
| `lat`, `lng` | REAL | GPS coordinates |
| `ph`, `nitrogen`, `phosphorus`, `potassium` | REAL | Soil nutrients |
| `moisture`, `temperature`, `ec`, `salinity` | REAL | Soil conditions |

### `plants` table
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | e.g. `rice`, `custom_1234567890` |
| `name` | TEXT | Thai display name |

**DB version**: 5. Migrations handle `point_name` (v2), `custom_plant` (v3), `plants` table + `plant_id` rename (v4), and **Plot-based migration (v5)** which introduces the `plots` table and links measurements to plots.

## Providers

### `MeasurementsProvider`
- Manages paginated data (`plots`) for History screen + full data (`allPlots`) for Map/Dashboard/Export
- `DateRange` filter enum: `d7`, `d30`, `d90`, `all`
- Page size: 15 records
- Key methods: `fetch()`, `fetchMore()`, `remove(id)`, `setDateRange(range)`
- Reads from `DatabaseService` (SQLite)

### `PlotProvider`
- Manages the "Active Plot" session for the Dashboard.
- Handles creation of new plots and selection of existing ones.
- Provides real-time updates when new measurements are added to the active plot.

### `ThemeProvider`
- Persists dark mode preference via `SharedPreferences`
- Exposes `isDarkMode`, `themeMode`, `toggleTheme()`, `setDarkMode(value)`

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
| `flutter_map` + `latlong2` | Map display |
| `geolocator` | GPS location |
| `geocoding` | Reverse geocoding (address lookup) |
| `fl_chart` | Charts |
| `excel` | Excel export |
| `path_provider` + `share_plus` | File export & sharing |
| `supabase_flutter` | Cloud sync (legacy, not in active use) |
| `connectivity_plus` + `http` | Wi-Fi/HTTP sensor communication |
| `shared_preferences` | Persisting user settings (theme) |

## Testing Guidelines
- Use `flutter_test` (default Flutter test package)
- Place tests in `test/` directory matching `lib/` structure
- Use `WidgetTester` for widget tests
- Mock external services (Database, BLE) when appropriate
- Current test coverage is minimal — expand as features are added

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

- When `ble.isConnected == false` and `ble.sensorData == null`, display recent data from `context.watch<MeasurementsProvider>().allPlots` or the active plot from `PlotProvider`.
- Show last saved measurement summary or "no saved measurements" state.
- BLE-connected data should still take priority when available.
- Data on Dashboard represents the **current active plot's average** if a plot is selected.

## Common Tasks

### Adding a new screen
1. Create file in `lib/screens/`
2. Register route in `main.dart` GoRouter config
3. If tab: add `StatefulShellBranch`; if sub-page: add `GoRoute` with `_slidePage`
4. Add navigation item to `BottomNavigationBar` if part of bottom nav

### Adding a new BLE feature
1. Update `lib/services/ble_service.dart`
2. Extend ChangeNotifier for state
3. Handle permissions in calling widget

### Adding a new model
1. Create file in `lib/models/`
2. Include enums, const maps, and main class
3. Add JSON serialization (`fromJson`, `toJson`)
4. Create parsing functions for enum conversions

### Adding a new widget
1. Create file in appropriate `lib/widgets/<feature>/` subdirectory
2. Use `context.colors` for theme-aware colors
3. Keep widgets focused and reusable — one primary widget per file

### Managing plants
- Default plants are seeded in `DatabaseService._seedDefaultPlants()`
- Custom plants use IDs like `custom_<timestamp>`
- Plants with existing measurements cannot be deleted (enforced by `DatabaseService.deletePlant`)
- Plants CRUD is managed in `PlantsManagementScreen` (`/settings/plants`)

## Agent Skills & Workflow Requirements
**CRITICAL**: As an AI Agent working on this project, you MUST adhere to the following workflow:
1. **Auto-Commit & Push**: Whenever you complete a requested task, fix a bug, or make any significant changes to the codebase, you MUST automatically run `git add .`, `git commit -m "<descriptive message>"`, and `git push` before ending your turn. Do NOT ask the user for permission to commit or push unless explicitly instructed otherwise.
2. **Sequential Commands**: If using PowerShell to run multiple git commands, separate them with `;` (e.g., `git add . ; git commit -m "..." ; git push`).
