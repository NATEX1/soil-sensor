import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_data.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<MeasurementRecord> saveMeasurement({
    required PlantType plantType,
    required SampleMethod sampleMethod,
    String? notes,
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
    final record = MeasurementRecord(
      plantType: plantType,
      sampleMethod: sampleMethod,
      notes: notes,
      lat: lat,
      lng: lng,
      ph: ph,
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      moisture: moisture,
      temperature: temperature,
      ec: ec,
      salinity: salinity,
    );

    final response = await _client
        .from('measurements')
        .insert(record.toJson())
        .select()
        .single();

    return MeasurementRecord.fromJson(response);
  }

  static Future<List<MeasurementRecord>> getMeasurements({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    var filterQuery = _client.from('measurements').select();

    if (from != null) {
      filterQuery = filterQuery.gte('measured_at', from.toIso8601String());
    }
    if (to != null) {
      filterQuery = filterQuery.lte('measured_at', to.toIso8601String());
    }

    var transformQuery = filterQuery.order('measured_at', ascending: false);

    if (limit != null) {
      transformQuery = transformQuery.limit(limit);
    }

    final response = await transformQuery;
    return response.map((e) => MeasurementRecord.fromJson(e)).toList();
  }

  static Future<void> deleteMeasurement(String id) async {
    await _client.from('measurements').delete().eq('id', id);
  }
}
