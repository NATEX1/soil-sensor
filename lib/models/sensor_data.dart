enum SoilStatus { low, normal, high }

enum SampleMethod { surface0_15, deep15_30, deep30_60 }

// Legacy default mappings for seeding and backward compatibility
const Map<String, String> defaultPlants = {
  'rice': 'ข้าว',
  'corn': 'ข้าวโพด',
  'cassava': 'มันสำปะหลัง',
  'sugarcane': 'อ้อย',
  'rubber': 'ยางพารา',
};

const Map<SampleMethod, String> sampleMethodLabels = {
  SampleMethod.surface0_15: 'เก็บผิวดิน 0-15 cm',
  SampleMethod.deep15_30: 'เก็บลึก 15-30 cm',
  SampleMethod.deep30_60: 'เก็บลึก 30-60 cm',
};

const Map<SampleMethod, String> sampleMethodValues = {
  SampleMethod.surface0_15: 'surface_0_15',
  SampleMethod.deep15_30: 'deep_15_30',
  SampleMethod.deep30_60: 'deep_30_60',
};

SampleMethod sampleMethodFromString(String s) =>
    sampleMethodValues.entries.firstWhere((e) => e.value == s, orElse: () => const MapEntry(SampleMethod.surface0_15, 'surface_0_15')).key;

class SensorData {
  final double ph;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double moisture;
  final double temperature;
  final double ec;
  final double salinity;

  const SensorData({
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.moisture,
    required this.temperature,
    required this.ec,
    required this.salinity,
  });

  double operator [](String key) {
    switch (key) {
      case 'ph': return ph;
      case 'nitrogen': return nitrogen;
      case 'phosphorus': return phosphorus;
      case 'potassium': return potassium;
      case 'moisture': return moisture;
      case 'temperature': return temperature;
      case 'ec': return ec;
      case 'salinity': return salinity;
      default: return 0;
    }
  }
}

class MeasurementRecord extends SensorData {
  final String? id;
  final String? userId;
  final DateTime? measuredAt;
  final String plantId;
  final String plantName;
  final SampleMethod sampleMethod;
  final String? notes;
  final double lat;
  final double lng;
  final String? pointName;

  const MeasurementRecord({
    this.id,
    this.userId,
    this.measuredAt,
    required this.plantId,
    required this.plantName,
    required this.sampleMethod,
    this.notes,
    this.pointName,
    required this.lat,
    required this.lng,
    required super.ph,
    required super.nitrogen,
    required super.phosphorus,
    required super.potassium,
    required super.moisture,
    required super.temperature,
    required super.ec,
    required super.salinity,
  });

  factory MeasurementRecord.fromJson(Map<String, dynamic> json) {
    return MeasurementRecord(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      measuredAt: json['measured_at'] != null ? DateTime.parse(json['measured_at'] as String) : null,
      plantId: json['plant_id'] as String? ?? json['plant_type'] as String? ?? 'unknown',
      plantName: json['plant_name'] as String? ?? 
                 json['custom_plant'] as String? ?? 
                 defaultPlants[json['plant_type'] as String?] ?? 
                 'ไม่ทราบชนิด',
      sampleMethod: sampleMethodFromString(json['sample_method'] as String? ?? 'surface_0_15'),
      notes: json['notes'] as String?,
      pointName: json['point_name'] as String?,
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      ph: (json['ph'] as num).toDouble(),
      nitrogen: (json['nitrogen'] as num).toDouble(),
      phosphorus: (json['phosphorus'] as num).toDouble(),
      potassium: (json['potassium'] as num).toDouble(),
      moisture: (json['moisture'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      ec: (json['ec'] as num).toDouble(),
      salinity: (json['salinity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (userId != null) 'user_id': userId,
    if (measuredAt != null) 'measured_at': measuredAt!.toIso8601String(),
    'plant_id': plantId,
    'sample_method': sampleMethodValues[sampleMethod],
    if (notes != null) 'notes': notes,
    if (pointName != null) 'point_name': pointName,
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
}
