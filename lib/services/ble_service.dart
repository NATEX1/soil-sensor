import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';

const String serviceUuid = '12345678-1234-1234-1234-123456789abc';
const String charUuid = 'abcd1234-ab12-ab12-ab12-abcdef123456';
const String deviceName = 'SoilSensor';

class BleService extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  Timer? _demoTimer;

  final List<BluetoothDevice> _foundDevices = [];
  bool _isScanning = false;
  bool _isDemoMode = false;
  SensorData? _sensorData;
  DateTime? _lastUpdate;
  String? _error;

  List<BluetoothDevice> get foundDevices => List.unmodifiable(_foundDevices);
  bool get isScanning => _isScanning;
  bool get isDemoMode => _isDemoMode;
  bool get isConnected => _connectedDevice != null || _isDemoMode;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  SensorData? get sensorData => _sensorData;
  DateTime? get lastUpdate => _lastUpdate;
  String? get error => _error;

  Future<void> startScan() async {
    if (_isDemoMode) {
      await disconnect();
    }
    _foundDevices.clear();
    _error = null;
    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.device.platformName;
          if (name == deviceName && !_foundDevices.any((d) => d.remoteId == r.device.remoteId)) {
            _foundDevices.add(r.device);
            notifyListeners();
          }
        }
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning) {
          _isScanning = false;
          notifyListeners();
        }
      });
    } catch (e) {
      _error = 'ไม่สามารถสแกนได้: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    try {
      await stopScan();
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _notifySubscription?.cancel();
          notifyListeners();
        }
      });

      await _startNotifications(device);
      notifyListeners();
    } catch (e) {
      _error = 'ไม่สามารถเชื่อมต่อกับอุปกรณ์ได้: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _startNotifications(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        for (final char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == charUuid) {
            await char.setNotifyValue(true);
            _notifySubscription = char.onValueReceived.listen((value) {
              _parseSensorData(value);
            });
            return;
          }
        }
      }
    }
  }

  void _parseSensorData(List<int> value) {
    try {
      final decoded = utf8.decode(value);
      final raw = jsonDecode(decoded) as Map<String, dynamic>;
      final ec = (raw['ec'] as num).toDouble();
      _sensorData = SensorData(
        ph: (raw['ph'] as num).toDouble(),
        nitrogen: (raw['n'] as num).toDouble(),
        phosphorus: (raw['p'] as num).toDouble(),
        potassium: (raw['k'] as num).toDouble(),
        moisture: (raw['moisture'] as num).toDouble(),
        temperature: (raw['temp'] as num).toDouble(),
        ec: ec,
        salinity: calculateSalinity(ec),
      );
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (_) {
      // skip invalid data
    }
  }

  Future<void> disconnect() async {
    if (_isDemoMode) {
      _isDemoMode = false;
      _demoTimer?.cancel();
      _demoTimer = null;
      _sensorData = null;
      notifyListeners();
      return;
    }

    try {
      await _notifySubscription?.cancel();
      await _connectionSubscription?.cancel();
      await _connectedDevice?.disconnect();
    } finally {
      _connectedDevice = null;
      notifyListeners();
    }
  }

  void startDemoMode() {
    _isDemoMode = true;
    _connectedDevice = null;
    _error = null;
    _isScanning = false;
    _scanSubscription?.cancel();
    
    _updateDemoData();
    
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateDemoData();
    });
    
    notifyListeners();
  }

  void _updateDemoData() {
    final random = Random();
    final ec = 1000.0 + random.nextDouble() * 500.0;
    
    _sensorData = SensorData(
      ph: 6.0 + random.nextDouble() * 1.5,
      nitrogen: 40.0 + random.nextDouble() * 20.0,
      phosphorus: 20.0 + random.nextDouble() * 10.0,
      potassium: 30.0 + random.nextDouble() * 15.0,
      moisture: 40.0 + random.nextDouble() * 20.0,
      temperature: 25.0 + random.nextDouble() * 5.0,
      ec: ec,
      salinity: calculateSalinity(ec),
    );
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }
}
