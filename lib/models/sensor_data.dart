enum SoilStatus { low, normal, high }

enum PlantType { rice, corn, cassava, sugarcane, rubber, other }

enum SampleMethod { surface0_15, deep15_30, deep30_60 }

const Map<PlantType, String> plantTypeLabels = {
  PlantType.rice: 'ข้าว',
  PlantType.corn: 'ข้าวโพด',
  PlantType.cassava: 'มันสำปะหลัง',
  PlantType.sugarcane: 'อ้อย',
  PlantType.rubber: 'ยางพารา',
  PlantType.other: 'อื่นๆ',
};

const Map<SampleMethod, String> sampleMethodLabels = {
  SampleMethod.surface0_15: 'เก็บผิวดิน 0-15 cm',
  SampleMethod.deep15_30: 'เก็บลึก 15-30 cm',
  SampleMethod.deep30_60: 'เก็บลึก 30-60 cm',
};

const Map<PlantType, String> plantTypeValues = {
  PlantType.rice: 'rice',
  PlantType.corn: 'corn',
  PlantType.cassava: 'cassava',
  PlantType.sugarcane: 'sugarcane',
  PlantType.rubber: 'rubber',
  PlantType.other: 'other',
};

const Map<SampleMethod, String> sampleMethodValues = {
  SampleMethod.surface0_15: 'surface_0_15',
  SampleMethod.deep15_30: 'deep_15_30',
  SampleMethod.deep30_60: 'deep_30_60',
};

PlantType plantTypeFromString(String s) =>
    plantTypeValues.entries.firstWhere((e) => e.value == s, orElse: () => const MapEntry(PlantType.other, 'other')).key;

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
  final PlantType plantType;
  final SampleMethod sampleMethod;
  final String? notes;
  final double lat;
  final double lng;
  final String? pointName;
  final String? customPlant;

  /// Display-friendly plant name: uses customPlant when plantType is 'other'
  String get plantLabel =>
      plantType == PlantType.other && customPlant != null && customPlant!.isNotEmpty
          ? customPlant!
          : plantTypeLabels[plantType] ?? 'อื่นๆ';

  const MeasurementRecord({
    this.id,
    this.userId,
    this.measuredAt,
    required this.plantType,
    required this.sampleMethod,
    this.notes,
    this.pointName,
    this.customPlant,
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
      plantType: plantTypeFromString(json['plant_type'] as String? ?? 'other'),
      sampleMethod: sampleMethodFromString(json['sample_method'] as String? ?? 'surface_0_15'),
      notes: json['notes'] as String?,
      pointName: json['point_name'] as String?,
      customPlant: json['custom_plant'] as String?,
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
    'plant_type': plantTypeValues[plantType],
    'sample_method': sampleMethodValues[sampleMethod],
    if (notes != null) 'notes': notes,
    if (pointName != null) 'point_name': pointName,
    if (customPlant != null) 'custom_plant': customPlant,
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
