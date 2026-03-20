import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/sensor_data.dart';
import '../models/calculations.dart';

const String defaultDeviceIp = '192.168.4.1'; // Default IP when device is in AP mode
const int defaultPort = 80;
const String apiEndpoint = '/api/sensor';

class WiFiService extends ChangeNotifier {
  String? _deviceIp;
  int _port = defaultPort;
  bool _isConnected = false;
  bool _isScanning = false;
  SensorData? _sensorData;
  DateTime? _lastUpdate;
  String? _error;
  Timer? _pollingTimer;

  String? get deviceIp => _deviceIp;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  SensorData? get sensorData => _sensorData;
  DateTime? get lastUpdate => _lastUpdate;
  String? get error => _error;

  /// Check if device is reachable at given IP
  Future<bool> checkDevice(String ip, {int port = defaultPort}) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:$port$apiEndpoint'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Scan local network for device
  Future<void> scanForDevice() async {
    _isScanning = true;
    _error = null;
    notifyListeners();

    try {
      // Check default IP first
      if (await checkDevice(defaultDeviceIp)) {
        await connect(defaultDeviceIp);
        _isScanning = false;
        notifyListeners();
        return;
      }

      // Scan local subnet
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.wifi) {
        // Try common IP ranges
        final List<String> ipsToTry = [];
        
        // Generate IPs to scan (192.168.1.x and 192.168.0.x)
        for (int i = 1; i <= 254; i++) {
          ipsToTry.add('192.168.1.$i');
          ipsToTry.add('192.168.0.$i');
        }

        // Scan in parallel batches
        const batchSize = 10;
        for (int i = 0; i < ipsToTry.length; i += batchSize) {
          final batch = ipsToTry.skip(i).take(batchSize).toList();
          final results = await Future.wait(
            batch.map((ip) => checkDevice(ip)),
          );

          for (int j = 0; j < results.length; j++) {
            if (results[j]) {
              await connect(batch[j]);
              _isScanning = false;
              notifyListeners();
              return;
            }
          }
        }
      }

      _error = 'ไม่พบอุปกรณ์ในเครือข่าย';
    } catch (e) {
      _error = 'ไม่สามารถสแกนได้: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Connect to device at specific IP
  Future<void> connect(String ip, {int port = defaultPort}) async {
    try {
      _deviceIp = ip;
      _port = port;
      
      // Test connection
      final response = await http
          .get(Uri.parse('http://$_deviceIp:$_port$apiEndpoint'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _isConnected = true;
        _parseSensorData(response.body);
        _startPolling();
        notifyListeners();
      } else {
        throw Exception('Device returned status ${response.statusCode}');
      }
    } catch (e) {
      _error = 'ไม่สามารถเชื่อมต่อได้: $e';
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _stopPolling();
    _deviceIp = null;
    _isConnected = false;
    notifyListeners();
  }

  /// Start polling for sensor data
  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchSensorData(),
    );
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Fetch sensor data from device
  Future<void> _fetchSensorData() async {
    if (_deviceIp == null || !_isConnected) return;

    try {
      final response = await http
          .get(Uri.parse('http://$_deviceIp:$_port$apiEndpoint'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        _parseSensorData(response.body);
      } else {
        _error = 'Device error: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Connection lost: $e';
      _isConnected = false;
      _stopPolling();
    }
    notifyListeners();
  }

  /// Parse sensor data from JSON
  void _parseSensorData(String jsonString) {
    try {
      final raw = jsonDecode(jsonString) as Map<String, dynamic>;
      final ec = (raw['ec'] as num?)?.toDouble() ?? 0;
      
      _sensorData = SensorData(
        ph: (raw['ph'] as num?)?.toDouble() ?? 0,
        nitrogen: (raw['n'] as num?)?.toDouble() ?? 0,
        phosphorus: (raw['p'] as num?)?.toDouble() ?? 0,
        potassium: (raw['k'] as num?)?.toDouble() ?? 0,
        moisture: (raw['moisture'] as num?)?.toDouble() ?? 0,
        temperature: (raw['temp'] as num?)?.toDouble() ?? 0,
        ec: ec,
        salinity: calculateSalinity(ec),
      );
      _lastUpdate = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Invalid data format: $e';
    }
  }

  /// Send configuration to device
  Future<bool> sendConfig(Map<String, dynamic> config) async {
    if (_deviceIp == null || !_isConnected) return false;

    try {
      final response = await http
          .post(
            Uri.parse('http://$_deviceIp:$_port/api/config'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(config),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      _error = 'Failed to send config: $e';
      return false;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
