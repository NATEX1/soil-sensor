import 'sensor_data.dart';

class Threshold {
  final double low;
  final double high;
  final String unit;
  const Threshold({required this.low, required this.high, required this.unit});
}

const Map<String, Threshold> thresholds = {
  'ph':          Threshold(low: 5.5,  high: 7.5,  unit: ''),
  'nitrogen':    Threshold(low: 150,  high: 300,  unit: 'mg/kg'),
  'phosphorus':  Threshold(low: 30,   high: 60,   unit: 'mg/kg'),
  'potassium':   Threshold(low: 150,  high: 250,  unit: 'mg/kg'),
  'moisture':    Threshold(low: 20,   high: 60,   unit: '%'),
  'temperature': Threshold(low: 15,   high: 35,   unit: '°C'),
  'ec':          Threshold(low: 0,    high: 2.0,  unit: 'dS/m'),
  'salinity':    Threshold(low: 0,    high: 1.5,  unit: 'ppt'),
};

const Map<String, String> sensorLabels = {
  'ph':          'pH',
  'nitrogen':    'ไนโตรเจน (N)',
  'phosphorus':  'ฟอสฟอรัส (P)',
  'potassium':   'โพแทสเซียม (K)',
  'moisture':    'ความชื้น',
  'temperature': 'อุณหภูมิ',
  'ec':          'EC',
  'salinity':    'ความเค็ม',
};

const Map<SoilStatus, String> statusLabels = {
  SoilStatus.low:    'ต่ำ',
  SoilStatus.normal: 'ปกติ',
  SoilStatus.high:   'สูง',
};

const Map<String, Map<SoilStatus, String>> recommendations = {
  'ph': {
    SoilStatus.low:    'ดินเป็นกรดมากเกินไป ควรใส่ปูนขาว (CaCO₃) เพื่อปรับ pH ให้สูงขึ้น',
    SoilStatus.normal: 'ค่า pH อยู่ในระดับที่เหมาะสม ไม่จำเป็นต้องปรับ',
    SoilStatus.high:   'ดินเป็นด่างมากเกินไป ควรใส่กำมะถัน (S) หรือปุ๋ยแอมโมเนียมซัลเฟตเพื่อลด pH',
  },
  'nitrogen': {
    SoilStatus.low:    'ไนโตรเจนต่ำ ควรใส่ปุ๋ยยูเรีย (46-0-0) หรือแอมโมเนียมซัลเฟต (21-0-0)',
    SoilStatus.normal: 'ปริมาณไนโตรเจนอยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'ไนโตรเจนสูงเกินไป ควรลดการใส่ปุ๋ยไนโตรเจนและเพิ่มการระบายน้ำ',
  },
  'phosphorus': {
    SoilStatus.low:    'ฟอสฟอรัสต่ำ ควรใส่ปุ๋ยซุปเปอร์ฟอสเฟต (0-46-0) หรือ DAP (18-46-0)',
    SoilStatus.normal: 'ปริมาณฟอสฟอรัสอยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'ฟอสฟอรัสสูงเกินไป ควรหยุดใส่ปุ๋ยฟอสฟอรัสชั่วคราว',
  },
  'potassium': {
    SoilStatus.low:    'โพแทสเซียมต่ำ ควรใส่ปุ๋ยโพแทสเซียมคลอไรด์ (0-0-60) หรือ KNO₃',
    SoilStatus.normal: 'ปริมาณโพแทสเซียมอยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'โพแทสเซียมสูงเกินไป ควรลดการใส่ปุ๋ยโพแทสเซียม',
  },
  'moisture': {
    SoilStatus.low:    'ดินแห้งเกินไป ควรให้น้ำเพิ่มเติมหรือปรับระบบชลประทาน',
    SoilStatus.normal: 'ความชื้นดินอยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'ดินชื้นเกินไป ควรปรับปรุงการระบายน้ำและลดการให้น้ำ',
  },
  'temperature': {
    SoilStatus.low:    'อุณหภูมิดินต่ำ อาจส่งผลต่อการเจริญเติบโตของพืช พิจารณาใช้พลาสติกคลุมดิน',
    SoilStatus.normal: 'อุณหภูมิดินอยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'อุณหภูมิดินสูง ควรคลุมดินด้วยฟางหรือวัสดุคลุมดินเพื่อลดความร้อน',
  },
  'ec': {
    SoilStatus.low:    'ค่า EC ต่ำ แสดงว่าดินมีธาตุอาหารน้อย ควรเพิ่มปุ๋ย',
    SoilStatus.normal: 'ค่า EC อยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'ค่า EC สูง ดินอาจมีเกลือสะสม ควรล้างดินด้วยน้ำและปรับปรุงการระบายน้ำ',
  },
  'salinity': {
    SoilStatus.low:    'ความเค็มต่ำ ดินมีสภาพปกติ',
    SoilStatus.normal: 'ความเค็มอยู่ในระดับที่เหมาะสม',
    SoilStatus.high:   'ดินเค็มสูง ควรล้างเกลือออกด้วยการให้น้ำมากๆ และปลูกพืชทนเค็ม',
  },
};

SoilStatus getSoilStatus(String key, double value) {
  final t = thresholds[key];
  if (t == null) return SoilStatus.normal;
  if (value < t.low) return SoilStatus.low;
  if (value > t.high) return SoilStatus.high;
  return SoilStatus.normal;
}

double calculateSalinity(double ec) {
  return double.parse((ec * 0.64).toStringAsFixed(2));
}

// ─── Cassava Variety Data ─────────────────────────────────────────────────

class CassavaVariety {
  final String id;
  final String name;
  final String shortCode;
  final String description;
  final double minPh;
  final double maxPh;
  final double minN;
  final double maxN;
  final double minP;
  final double maxP;
  final double minK;
  final double maxK;
  final String droughtTolerance;
  final String yieldPotential;
  final String starchRange;
  final String baseFertCode;
  final String baseFertName;
  final String topFertCode;
  final String topFertName;
  final String baseFertRate;
  final String topFertRate;

  const CassavaVariety({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.description,
    required this.minPh,
    required this.maxPh,
    required this.minN,
    required this.maxN,
    required this.minP,
    required this.maxP,
    required this.minK,
    required this.maxK,
    required this.droughtTolerance,
    required this.yieldPotential,
    required this.starchRange,
    required this.baseFertCode,
    required this.baseFertName,
    required this.topFertCode,
    required this.topFertName,
    required this.baseFertRate,
    required this.topFertRate,
  });

  factory CassavaVariety.fromJson(Map<String, dynamic> json) {
    return CassavaVariety(
      id: json['id'].toString(),
      name: json['name'] as String,
      shortCode: json['short_code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      minPh: (json['min_ph'] as num?)?.toDouble() ?? 5.5,
      maxPh: (json['max_ph'] as num?)?.toDouble() ?? 7.5,
      minN: (json['min_n'] as num?)?.toDouble() ?? 80.0,
      maxN: (json['max_n'] as num?)?.toDouble() ?? 350.0,
      minP: (json['min_p'] as num?)?.toDouble() ?? 15.0,
      maxP: (json['max_p'] as num?)?.toDouble() ?? 80.0,
      minK: (json['min_k'] as num?)?.toDouble() ?? 100.0,
      maxK: (json['max_k'] as num?)?.toDouble() ?? 350.0,
      droughtTolerance: json['drought_tolerance'] as String? ?? '-',
      yieldPotential: json['yield_potential'] as String? ?? '-',
      starchRange: json['starch_range'] as String? ?? '-',
      baseFertCode: json['base_fert_code'] as String? ?? 'สูตรเสมอ / อินทรีย์',
      baseFertName: json['base_fert_name'] as String? ?? 'ปุ๋ยพื้นฐาน',
      topFertCode: json['top_fert_code'] as String? ?? 'สูตรบำรุง',
      topFertName: json['top_fert_name'] as String? ?? 'ปุ๋ยเสริม',
      baseFertRate: json['base_fert_rate'] as String? ?? 'ตามความเหมาะสม',
      topFertRate: json['top_fert_rate'] as String? ?? 'ตามความต้องการ',
    );
  }
}

List<PlantSuitability> evaluateSuitability(SensorData avgData, List<CassavaVariety> varieties) {
  final results = <PlantSuitability>[];

  for (final v in varieties) {
    double score = 100.0;
    final Map<String, String> advice = {};

    // Check pH (weight: 25)
    if (avgData.ph < v.minPh) {
      final deficit = ((v.minPh - avgData.ph) / v.minPh).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['ph'] = 'ดินเป็นกรดเกินไป (pH ${avgData.ph.toStringAsFixed(1)} / ต้องการ ${v.minPh}–${v.maxPh}) — ใส่ปูนขาว (CaCO₃) 200-500 กก./ไร่';
    } else if (avgData.ph > v.maxPh) {
      final excess = ((avgData.ph - v.maxPh) / v.maxPh).clamp(0.0, 1.0);
      score -= 25 * excess;
      advice['ph'] = 'ดินเป็นด่างเกินไป (pH ${avgData.ph.toStringAsFixed(1)} / ต้องการ ${v.minPh}–${v.maxPh}) — ใส่กำมะถัน (S) หรือปุ๋ยแอมโมเนียมซัลเฟต (21-0-0)';
    }

    // Check N (weight: 25)
    if (avgData.nitrogen < v.minN) {
      final deficit = ((v.minN - avgData.nitrogen) / v.minN).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['nitrogen'] = 'ไนโตรเจนต่ำ (${avgData.nitrogen.toStringAsFixed(0)} mg/kg / ต้องการ ${v.minN}–${v.maxN}) — ใส่ยูเรีย (46-0-0) 25-30 กก./ไร่';
    } else if (avgData.nitrogen > v.maxN) {
      final excess = ((avgData.nitrogen - v.maxN) / v.maxN).clamp(0.0, 1.0);
      score -= 20 * excess;
      advice['nitrogen'] = 'ไนโตรเจนสูงเกินไป (${avgData.nitrogen.toStringAsFixed(0)} mg/kg / ต้องการ ${v.minN}–${v.maxN}) — หยุดใส่ปุ๋ยไนโตรเจน ระวังการเจริญเติบโตทางใบมากเกินไป';
    }

    // Check P (weight: 25)
    if (avgData.phosphorus < v.minP) {
      final deficit = ((v.minP - avgData.phosphorus) / v.minP).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['phosphorus'] = 'ฟอสฟอรัสต่ำ (${avgData.phosphorus.toStringAsFixed(0)} mg/kg / ต้องการ ${v.minP}–${v.maxP}) — ใส่ซุปเปอร์ฟอสเฟต (0-46-0) หรือ DAP (18-46-0)';
    } else if (avgData.phosphorus > v.maxP) {
      final excess = ((avgData.phosphorus - v.maxP) / v.maxP).clamp(0.0, 1.0);
      score -= 15 * excess;
      advice['phosphorus'] = 'ฟอสฟอรัสสูงเกินไป (${avgData.phosphorus.toStringAsFixed(0)} mg/kg / ต้องการ ${v.minP}–${v.maxP}) — หยุดใส่ปุ๋ยฟอสฟอรัส อาจรบกวนการดูดซึมธาตุอาหารอื่น';
    }

    // Check K (weight: 25)
    if (avgData.potassium < v.minK) {
      final deficit = ((v.minK - avgData.potassium) / v.minK).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['potassium'] = 'โพแทสเซียมต่ำ (${avgData.potassium.toStringAsFixed(0)} mg/kg / ต้องการ ${v.minK}–${v.maxK}) — ใส่ KCl (0-0-60) 25-30 กก./ไร่';
    } else if (avgData.potassium > v.maxK) {
      final excess = ((avgData.potassium - v.maxK) / v.maxK).clamp(0.0, 1.0);
      score -= 20 * excess;
      advice['potassium'] = 'โพแทสเซียมสูงเกินไป (${avgData.potassium.toStringAsFixed(0)} mg/kg / ต้องการ ${v.minK}–${v.maxK}) — หยุดใส่ปุ๋ยโพแทสเซียม ระวังปัญหาความเป็นพิษของเกลือ';
    }

    if (advice.isEmpty) {
      advice['general'] = 'ดินเหมาะสมอย่างยิ่งสำหรับ${v.name} — สามารถปลูกได้เลยโดยใช้ปุ๋ยรองพื้น ${v.baseFertCode} ตามอัตราแนะนำ';
    }

    results.add(PlantSuitability(
      plantId: v.id,
      plantName: v.name,
      scorePercent: score.clamp(0, 100),
      recommendations: advice,
    ));
  }

  results.sort((a, b) => b.scorePercent.compareTo(a.scorePercent));
  return results.take(3).toList();
}

/// Returns ALL varieties sorted by score descending
List<PlantSuitability> evaluateAllSuitability(SensorData avgData, List<CassavaVariety> varieties) {
  final results = <PlantSuitability>[];

  for (final v in varieties) {
    double score = 100.0;
    final Map<String, String> advice = {};

    if (avgData.ph < v.minPh) {
      final deficit = ((v.minPh - avgData.ph) / v.minPh).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['ph'] = 'pH ต่ำเกินไป (${avgData.ph.toStringAsFixed(1)} / ต้องการ ${v.minPh}–${v.maxPh})';
    } else if (avgData.ph > v.maxPh) {
      final excess = ((avgData.ph - v.maxPh) / v.maxPh).clamp(0.0, 1.0);
      score -= 25 * excess;
      advice['ph'] = 'pH สูงเกินไป (${avgData.ph.toStringAsFixed(1)} / ต้องการ ${v.minPh}–${v.maxPh})';
    }
    if (avgData.nitrogen < v.minN) {
      final deficit = ((v.minN - avgData.nitrogen) / v.minN).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['nitrogen'] = 'N ต่ำ (${avgData.nitrogen.toStringAsFixed(0)} / ต้องการ ${v.minN}–${v.maxN})';
    } else if (avgData.nitrogen > v.maxN) {
      final excess = ((avgData.nitrogen - v.maxN) / v.maxN).clamp(0.0, 1.0);
      score -= 20 * excess;
      advice['nitrogen'] = 'N สูงเกินไป (${avgData.nitrogen.toStringAsFixed(0)} / ต้องการ ${v.minN}–${v.maxN})';
    }
    if (avgData.phosphorus < v.minP) {
      final deficit = ((v.minP - avgData.phosphorus) / v.minP).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['phosphorus'] = 'P ต่ำ (${avgData.phosphorus.toStringAsFixed(0)} / ต้องการ ${v.minP}–${v.maxP})';
    } else if (avgData.phosphorus > v.maxP) {
      final excess = ((avgData.phosphorus - v.maxP) / v.maxP).clamp(0.0, 1.0);
      score -= 15 * excess;
      advice['phosphorus'] = 'P สูงเกินไป (${avgData.phosphorus.toStringAsFixed(0)} / ต้องการ ${v.minP}–${v.maxP})';
    }
    if (avgData.potassium < v.minK) {
      final deficit = ((v.minK - avgData.potassium) / v.minK).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['potassium'] = 'K ต่ำ (${avgData.potassium.toStringAsFixed(0)} / ต้องการ ${v.minK}–${v.maxK})';
    } else if (avgData.potassium > v.maxK) {
      final excess = ((avgData.potassium - v.maxK) / v.maxK).clamp(0.0, 1.0);
      score -= 20 * excess;
      advice['potassium'] = 'K สูงเกินไป (${avgData.potassium.toStringAsFixed(0)} / ต้องการ ${v.minK}–${v.maxK})';
    }
    if (advice.isEmpty) {
      advice['general'] = 'ดินเหมาะสมสำหรับ${v.name}';
    }

    results.add(PlantSuitability(
      plantId: v.id,
      plantName: v.name,
      scorePercent: score.clamp(0, 100),
      recommendations: advice,
    ));
  }

  results.sort((a, b) => b.scorePercent.compareTo(a.scorePercent));
  return results;
}
