enum SoilStatus { low, normal, high }

enum SampleMethod { surface0_15, deep15_30, deep30_60 }

// Default tuber crops (มันชนิดต่างๆ)
const Map<String, String> defaultPlants = {
  'cassava': 'เกษตรศาสตร์ 50',
  'sweet_potato': 'ห้วยบง 80',
  'potato': 'ระยอง 72',
  'jicama': 'ห้วยบง 60',
  'taro': 'เกษตรศาสตร์ 81',
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
  final SampleMethod sampleMethod;
  final String? notes;
  final double lat;
  final double lng;
  final String? pointName;
  final String? plotId;
  final String? soilType;
  final double? harvestAge;

  const MeasurementRecord({
    this.id,
    this.userId,
    this.measuredAt,
    required this.sampleMethod,
    this.notes,
    this.pointName,
    this.plotId,
    this.soilType,
    this.harvestAge,
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
      id: json['id']?.toString(),
      userId: json['user_id'] as String?,
      measuredAt: json['measured_at'] != null ? DateTime.parse(json['measured_at'] as String) : null,
      sampleMethod: sampleMethodFromString(json['sample_method'] as String? ?? 'surface_0_15'),
      notes: json['notes'] as String?,
      pointName: json['point_name'] as String?,
      plotId: (json['plot_id'] ?? json['group_id']) as String?,
      soilType: json['soil_type'] as String?,
      harvestAge: (json['harvest_age'] as num?)?.toDouble(),
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
    'sample_method': sampleMethodValues[sampleMethod],
    if (notes != null) 'notes': notes,
    if (pointName != null) 'point_name': pointName,
    if (plotId != null) 'plot_id': plotId,
    if (soilType != null) 'soil_type': soilType,
    if (harvestAge != null) 'harvest_age': harvestAge,
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

class PlotRecord extends SensorData {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? notes;
  final double? lat;
  final double? lng;
  final List<MeasurementRecord> measurements;

  const PlotRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    this.notes,
    this.lat,
    this.lng,
    required this.measurements,
    required super.ph,
    required super.nitrogen,
    required super.phosphorus,
    required super.potassium,
    required super.moisture,
    required super.temperature,
    required super.ec,
    required super.salinity,
  });

  int get measurementCount => measurements.length;
}

class PlantSuitability {
  final String plantId;
  final String plantName;
  final double scorePercent;
  final Map<String, String> recommendations; // key: sensorKey, value: advice

  const PlantSuitability({
    required this.plantId,
    required this.plantName,
    required this.scorePercent,
    required this.recommendations,
  });
}
