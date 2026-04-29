import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';

const String serviceUuid = 'b7185de0-2c63-4c74-8c21-f857dc3fb3eb';
const String charUuid = '229b07fd-7823-4cbe-814c-b08dcca03572';
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
  String? _rawData; // 🌟 เก็บข้อมูลดิบไปโชว์ในหน้าจอ 🌟

  List<BluetoothDevice> get foundDevices => List.unmodifiable(_foundDevices);
  bool get isScanning => _isScanning;
  bool get isDemoMode => _isDemoMode;
  bool get isConnected => _connectedDevice != null || _isDemoMode;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  SensorData? get sensorData => _sensorData;
  DateTime? get lastUpdate => _lastUpdate;
  String? get error => _error;
  String? get rawData => _rawData; // 🌟 Getter 🌟

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
      _error = _getFriendlyErrorMessage('ไม่สามารถสแกนได้', e);
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
      
      // 🌟 1. รอให้ GATT นิ่งสักครู่ก่อนทำอย่างอื่น 🌟
      await Future.delayed(const Duration(milliseconds: 1000));

      // 🌟 2. ขยายขนาดการรับส่งข้อมูลฝั่งแอปให้ตรงกับบอร์ด 🌟
      try {
        await device.requestMtu(512);
        // รอให้การขอ MTU เสร็จสมบูรณ์
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {}
      
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
      _error = _getFriendlyErrorMessage('ไม่สามารถเชื่อมต่อกับอุปกรณ์ได้', e);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _startNotifications(BluetoothDevice device) async {
    // 🌟 3. บังคับค้นหา Service ใหม่เพื่อให้เห็นค่าล่าสุด 🌟
    final services = await device.discoverServices();
    
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (final char in service.characteristics) {
          if (char.uuid.toString().toLowerCase() == charUuid.toLowerCase()) {
            
            // 🌟 4. เปิด Notification 🌟
            await char.setNotifyValue(true);
            
            // ยกเลิกของเก่าถ้ามี
            await _notifySubscription?.cancel();
            
            _notifySubscription = char.onValueReceived.listen((value) {
              if (kDebugMode) {
                print("🔹 BLE Data Received: ${utf8.decode(value)}");
              }
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
      String decoded = utf8.decode(value).trim();
      _rawData = decoded; // 🌟 บันทึกค่าที่ได้รับมา 🌟
      
      // 🌟 ระบบค้นหา JSON 🌟
      if (decoded.contains('{') && decoded.contains('}')) {
        decoded = decoded.substring(decoded.indexOf('{'), decoded.lastIndexOf('}') + 1);
      }

      final raw = jsonDecode(decoded) as Map<String, dynamic>;
      
      _sensorData = SensorData(
        ph: (raw['ph'] as num?)?.toDouble() ?? 0.0,
        nitrogen: (raw['n'] as num?)?.toDouble() ?? 0.0,
        phosphorus: (raw['p'] as num?)?.toDouble() ?? 0.0,
        potassium: (raw['k'] as num?)?.toDouble() ?? 0.0,
        moisture: (raw['moisture'] as num?)?.toDouble() ?? 0.0,
        temperature: (raw['temp'] as num?)?.toDouble() ?? 0.0,
        ec: (raw['ec'] as num?)?.toDouble() ?? 0.0,
        salinity: calculateSalinity((raw['ec'] as num?)?.toDouble() ?? 0.0),
      );
      _lastUpdate = DateTime.now();
      notifyListeners();
    } catch (e) {
      _rawData = "Error: $e | Raw: ${utf8.decode(value)}";
      if (kDebugMode) {
        print("❌ BLE Parse Error: $e");
        print("❌ Received Raw Data: ${utf8.decode(value)}");
      }
      notifyListeners();
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

  String _getFriendlyErrorMessage(String prefix, dynamic e) {
    final errorStr = e.toString().toLowerCase();
    
    if (errorStr.contains('bluetooth must be turned on') || 
        errorStr.contains('ble is turned off') || 
        errorStr.contains('cbmanagerstateunsupported') ||
        errorStr.contains('cbmanagerstatepoweredoff') ||
        errorStr.contains('bluetooth is disabled')) {
      return '$prefix: กรุณาเปิดบลูทูธบนสมาทโฟนของคุณ';
    }
    if (errorStr.contains('location') || 
        errorStr.contains('permission') || 
        errorStr.contains('denied')) {
      return '$prefix: กรุณาเปิดตำแหน่ง (Location) และอนุญาตการเข้าถึง';
    }
    if (errorStr.contains('timeout') || errorStr.contains('time out')) {
      return '$prefix: ใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง';
    }
    if (errorStr.contains('not found') || errorStr.contains('disconnected')) {
      return '$prefix: ไม่พบอุปกรณ์หรืออุปกรณ์ขาดการเชื่อมต่อ';
    }
    
    return '$prefix: เกิดข้อผิดพลาดของระบบ กรุณาลองเปิด-ปิดบลูทูธแล้วลองใหม่';
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
