import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models/sensor_data.dart';

class ApiService {
  static String get _baseUrl => Env.apiBaseUrl;

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (Env.apiKey.isNotEmpty) {
      headers['X-Api-Key'] = Env.apiKey;
    }
    return headers;
  }

  // ─── Measurements ──────────────────────────────────────────────────────────

  static Future<MeasurementRecord> saveMeasurement({
    required SampleMethod sampleMethod,
    String? notes,
    String? pointName,
    String? groupId,
    required double lat,
    required double lng,
    required double ph,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double moisture,
    required double temperature,
    required double ec,
    required double salinity,
  }) async {
    final body = {
      'plot_id': groupId,
      'sample_method': sampleMethodValues[sampleMethod],
      'notes': notes,
      'point_name': pointName,
      'lat': lat,
      'lng': lng,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'moisture': moisture,
      'temperature': temperature,
      'ec': ec,
      'salinity': salinity,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/measurements'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body);
      return MeasurementRecord.fromJson(json);
    } else {
      _handleError(res, 'บันทึกข้อมูลไม่สำเร็จ');
    }
  }

  static Future<void> deleteMeasurement(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/measurements/$id'),
      headers: _headers,
    );

    if (res.statusCode >= 400) {
      _handleError(res, 'ลบข้อมูลไม่สำเร็จ');
    }
  }

  static Future<List<MeasurementRecord>> getMeasurementsByGroupId(String groupId) async {
    final uri = Uri.parse('$_baseUrl/measurements').replace(queryParameters: {
      'plot_id': groupId,
    });
    
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'] as List;
      return data.map((j) => MeasurementRecord.fromJson(j)).toList();
    } else {
      _handleError(res, 'ดึงข้อมูลไม่สำเร็จ');
    }
  }

  // ─── Plots ─────────────────────────────────────────────────────────────────

  static Future<String> createPlot(String name, {String? notes, double? lat, double? lng}) async {
    final body = {
      'name': name,
      if (notes != null) 'notes': notes,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/plots'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body);
      return json['id'].toString();
    } else {
      _handleError(res, 'สร้างแปลงไม่สำเร็จ');
    }
  }

  static Future<List<PlotRecord>> getPlots({
    DateTime? from,
    DateTime? to,
    int? limit,
    int? offset,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    final uri = Uri.parse('$_baseUrl/plots').replace(queryParameters: params);
    
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'] as List;
      return data.map((p) => _parsePlotRecord(p)).toList();
    } else {
      _handleError(res, 'ดึงข้อมูลแปลงไม่สำเร็จ');
    }
  }

  static Future<int> getPlotsCount({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{'limit': '1'}; // Minimal payload just to get total
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final uri = Uri.parse('$_baseUrl/plots').replace(queryParameters: params);
    
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['total'] as int? ?? 0;
    } else {
      _handleError(res, 'ดึงจำนวนแปลงไม่สำเร็จ');
    }
  }

  static Future<void> deletePlot(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/plots/$id'),
      headers: _headers,
    );

    if (res.statusCode >= 400) {
      _handleError(res, 'ลบแปลงไม่สำเร็จ');
    }
  }

  // ─── Plants ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPlants() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/plants'),
      headers: _headers,
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      return List<Map<String, dynamic>>.from(data);
    } else {
      _handleError(res, 'ดึงข้อมูลพืชไม่สำเร็จ');
    }
  }

  static Future<String> addPlant(
    String name, {
    double? minPh,
    double? maxPh,
    double? minN,
    double? maxN,
    double? minP,
    double? maxP,
    double? minK,
    double? maxK,
  }) async {
    final body = {
      'name': name,
      if (minPh != null) 'min_ph': minPh,
      if (maxPh != null) 'max_ph': maxPh,
      if (minN != null) 'min_n': minN,
      if (maxN != null) 'max_n': maxN,
      if (minP != null) 'min_p': minP,
      if (maxP != null) 'max_p': maxP,
      if (minK != null) 'min_k': minK,
      if (maxK != null) 'max_k': maxK,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/plants'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body);
      return json['id'].toString();
    } else {
      _handleError(res, 'เพิ่มพืชไม่สำเร็จ');
    }
  }

  static Future<void> deletePlant(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/plants/$id'),
      headers: _headers,
    );

    if (res.statusCode >= 400) {
      _handleError(res, 'ลบข้อมูลพืชไม่สำเร็จ');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static PlotRecord _parsePlotRecord(Map<String, dynamic> json) {
    final measurementsJson = json['measurements'] as List? ?? [];
    final measurements = measurementsJson
        .map((j) => MeasurementRecord.fromJson(j))
        .toList();

    return PlotRecord(
      id: json['id'].toString(),
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      measurements: measurements,
      ph: (json['ph'] as num?)?.toDouble() ?? 0,
      nitrogen: (json['nitrogen'] as num?)?.toDouble() ?? 0,
      phosphorus: (json['phosphorus'] as num?)?.toDouble() ?? 0,
      potassium: (json['potassium'] as num?)?.toDouble() ?? 0,
      moisture: (json['moisture'] as num?)?.toDouble() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      ec: (json['ec'] as num?)?.toDouble() ?? 0,
      salinity: (json['salinity'] as num?)?.toDouble() ?? 0,
    );
  }

  static Never _handleError(http.Response res, String action) {
    String errorMessage = 'เซิร์ฟเวอร์มีปัญหา (HTTP ${res.statusCode})';
    try {
      final bodyStr = res.body.trim();
      if (bodyStr.startsWith('{')) {
        final json = jsonDecode(bodyStr);
        if (json['error'] != null) {
          errorMessage = json['error'].toString();
        } else if (json['message'] != null) {
          errorMessage = json['message'].toString();
        }
      } else if (bodyStr.toLowerCase().contains('<html')) {
        errorMessage = 'ไม่พบข้อมูลที่ร้องขอ หรือเซิร์ฟเวอร์มีปัญหา (HTTP ${res.statusCode})';
      } else if (bodyStr.isNotEmpty && bodyStr.length < 100) {
        errorMessage = bodyStr;
      }
    } catch (_) {}

    throw ApiException('$action: $errorMessage');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
