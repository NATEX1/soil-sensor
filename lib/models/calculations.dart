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
  final double minP;
  final double minK;
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
    required this.minP,
    required this.minK,
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
}

const Map<String, CassavaVariety> cassavaVarieties = {
  'ku50': CassavaVariety(
    id: 'ku50',
    name: 'เกษตรศาสตร์ 50',
    shortCode: 'KU50',
    description: 'สายพันธุ์ยอดนิยม ปรับตัวได้ดีในหลายสภาพดิน ให้ผลผลิตสูงและแป้งสูง',
    minPh: 5.5, maxPh: 7.5,
    minN: 80, minP: 15, minK: 100,
    droughtTolerance: 'สูง',
    yieldPotential: 'สูง',
    starchRange: '25-30%',
    baseFertCode: '15-15-15',
    baseFertName: 'สูตรเสมอ',
    topFertCode: '46-0-0',
    topFertName: 'ยูเรีย',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '25 กก./ไร่ อายุ 1-2 เดือน',
  ),
  'rayong1': CassavaVariety(
    id: 'rayong1',
    name: 'ระยอง 1',
    shortCode: 'R1',
    description: 'ให้ผลผลิตสูง ทนทานต่อโรค ปรับตัวได้ดีในดินร่วนและดินทราย',
    minPh: 5.5, maxPh: 7.0,
    minN: 100, minP: 20, minK: 120,
    droughtTolerance: 'ปานกลาง',
    yieldPotential: 'สูงมาก',
    starchRange: '22-28%',
    baseFertCode: '16-8-8',
    baseFertName: 'เน้นไนโตรเจน',
    topFertCode: '13-13-21',
    topFertName: 'เน้นโพแทสเซียม',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '50 กก./ไร่ อายุ 3-4 เดือน',
  ),
  'rayong5': CassavaVariety(
    id: 'rayong5',
    name: 'ระยอง 5',
    shortCode: 'R5',
    description: 'ทนแล้งดีเยี่ยม เหมาะกับพื้นที่ฝนน้อยหรือไม่มีชลประทาน',
    minPh: 5.0, maxPh: 6.5,
    minN: 80, minP: 15, minK: 100,
    droughtTolerance: 'สูงมาก',
    yieldPotential: 'ปานกลาง',
    starchRange: '20-26%',
    baseFertCode: '15-15-15',
    baseFertName: 'สูตรเสมอ',
    topFertCode: '0-0-60',
    topFertName: 'โพแทสเซียมคลอไรด์',
    baseFertRate: '40 กก./ไร่ ตอนปลูก',
    topFertRate: '20 กก./ไร่ อายุ 2-3 เดือน',
  ),
  'rayong7': CassavaVariety(
    id: 'rayong7',
    name: 'ระยอง 7',
    shortCode: 'R7',
    description: 'ให้ผลผลิตสูงมาก เหมาะกับดินที่มีความอุดมสมบูรณ์ดี',
    minPh: 5.5, maxPh: 7.5,
    minN: 100, minP: 20, minK: 130,
    droughtTolerance: 'ปานกลาง',
    yieldPotential: 'สูงมาก',
    starchRange: '24-30%',
    baseFertCode: '16-8-8',
    baseFertName: 'เน้นไนโตรเจน',
    topFertCode: '13-13-21',
    topFertName: 'เน้นโพแทสเซียม',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '50 กก./ไร่ อายุ 3-4 เดือน',
  ),
  'rayong9': CassavaVariety(
    id: 'rayong9',
    name: 'ระยอง 9',
    shortCode: 'R9',
    description: 'ปรับตัวได้ดี ให้ผลผลิตสม่ำเสมอ ทนทานต่อสภาพอากาศแปรปรวน',
    minPh: 5.5, maxPh: 7.0,
    minN: 90, minP: 18, minK: 120,
    droughtTolerance: 'ปานกลาง',
    yieldPotential: 'สูง',
    starchRange: '23-28%',
    baseFertCode: '15-15-15',
    baseFertName: 'สูตรเสมอ',
    topFertCode: '46-0-0',
    topFertName: 'ยูเรีย',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '25 กก./ไร่ อายุ 1-2 เดือน',
  ),
  'rayong11': CassavaVariety(
    id: 'rayong11',
    name: 'ระยอง 11',
    shortCode: 'R11',
    description: 'ทนโรคใบด่างได้ดี เหมาะกับพื้นที่ที่มีปัญหาโรคระบาด',
    minPh: 5.0, maxPh: 7.0,
    minN: 80, minP: 15, minK: 100,
    droughtTolerance: 'สูง',
    yieldPotential: 'สูง',
    starchRange: '22-28%',
    baseFertCode: '15-15-15',
    baseFertName: 'สูตรเสมอ',
    topFertCode: '13-13-21',
    topFertName: 'เน้นโพแทสเซียม',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '50 กก./ไร่ อายุ 3-4 เดือน',
  ),
  'huaybong60': CassavaVariety(
    id: 'huaybong60',
    name: 'ห้วยบง 60',
    shortCode: 'HB60',
    description: 'แป้งสูง เหมาะสำหรับอุตสาหกรรมแปรรูป ต้องการดินอุดมสมบูรณ์',
    minPh: 5.5, maxPh: 7.5,
    minN: 100, minP: 20, minK: 140,
    droughtTolerance: 'ต่ำ',
    yieldPotential: 'สูงมาก',
    starchRange: '28-34%',
    baseFertCode: '16-8-8',
    baseFertName: 'เน้นไนโตรเจน',
    topFertCode: '13-13-21',
    topFertName: 'เน้นโพแทสเซียม',
    baseFertRate: '60 กก./ไร่ ตอนปลูก',
    topFertRate: '60 กก./ไร่ อายุ 3-4 เดือน',
  ),
  'huaybong80': CassavaVariety(
    id: 'huaybong80',
    name: 'ห้วยบง 80',
    shortCode: 'HB80',
    description: 'ทนแล้งดี ปรับตัวได้หลายสภาพดิน ผลผลิตสูงและสม่ำเสมอ',
    minPh: 5.0, maxPh: 7.5,
    minN: 80, minP: 15, minK: 100,
    droughtTolerance: 'สูง',
    yieldPotential: 'สูง',
    starchRange: '24-30%',
    baseFertCode: '15-15-15',
    baseFertName: 'สูตรเสมอ',
    topFertCode: '0-0-60',
    topFertName: 'โพแทสเซียมคลอไรด์',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '25 กก./ไร่ อายุ 2-3 เดือน',
  ),
  'cmr38': CassavaVariety(
    id: 'cmr38',
    name: 'CMR38-125-77',
    shortCode: 'CMR38',
    description: 'สายพันธุ์ปรับปรุงใหม่ ให้ผลผลิตสูง ทนทานต่อโรคและแมลงได้ดี',
    minPh: 5.5, maxPh: 7.0,
    minN: 100, minP: 20, minK: 120,
    droughtTolerance: 'ปานกลาง',
    yieldPotential: 'สูงมาก',
    starchRange: '25-32%',
    baseFertCode: '16-8-8',
    baseFertName: 'เน้นไนโตรเจน',
    topFertCode: '13-13-21',
    topFertName: 'เน้นโพแทสเซียม',
    baseFertRate: '50 กก./ไร่ ตอนปลูก',
    topFertRate: '50 กก./ไร่ อายุ 3-4 เดือน',
  ),
};

// ─── Evaluate Cassava Suitability (top 3) ────────────────────────────────

List<PlantSuitability> evaluateSuitability(SensorData avgData) {
  final results = <PlantSuitability>[];

  for (final entry in cassavaVarieties.entries) {
    final v = entry.value;
    double score = 100.0;
    final Map<String, String> advice = {};

    // Check pH (weight: 25)
    if (avgData.ph < v.minPh) {
      final deficit = ((v.minPh - avgData.ph) / v.minPh).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['ph'] = 'ดินเป็นกรดเกินไป (pH ${avgData.ph.toStringAsFixed(1)} / ต้องการ ≥ ${v.minPh}) — ใส่ปูนขาว (CaCO₃) 200-500 กก./ไร่';
    } else if (avgData.ph > v.maxPh) {
      final excess = ((avgData.ph - v.maxPh) / v.maxPh).clamp(0.0, 1.0);
      score -= 25 * excess;
      advice['ph'] = 'ดินเป็นด่างเกินไป (pH ${avgData.ph.toStringAsFixed(1)} / ต้องการ ≤ ${v.maxPh}) — ใส่กำมะถัน (S) หรือปุ๋ยแอมโมเนียมซัลเฟต (21-0-0)';
    }

    // Check N (weight: 25)
    if (avgData.nitrogen < v.minN) {
      final deficit = ((v.minN - avgData.nitrogen) / v.minN).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['nitrogen'] = 'ไนโตรเจนต่ำ (${avgData.nitrogen.toStringAsFixed(0)} / ต้องการ ≥ ${v.minN} mg/kg) — ใส่ยูเรีย (46-0-0) 25-30 กก./ไร่';
    }

    // Check P (weight: 25)
    if (avgData.phosphorus < v.minP) {
      final deficit = ((v.minP - avgData.phosphorus) / v.minP).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['phosphorus'] = 'ฟอสฟอรัสต่ำ (${avgData.phosphorus.toStringAsFixed(0)} / ต้องการ ≥ ${v.minP} mg/kg) — ใส่ซุปเปอร์ฟอสเฟต (0-46-0) หรือ DAP (18-46-0)';
    }

    // Check K (weight: 25)
    if (avgData.potassium < v.minK) {
      final deficit = ((v.minK - avgData.potassium) / v.minK).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['potassium'] = 'โพแทสเซียมต่ำ (${avgData.potassium.toStringAsFixed(0)} / ต้องการ ≥ ${v.minK} mg/kg) — ใส่ KCl (0-0-60) 25-30 กก./ไร่';
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

/// Returns ALL cassava varieties sorted by score descending
List<PlantSuitability> evaluateAllSuitability(SensorData avgData) {
  final results = <PlantSuitability>[];

  for (final entry in cassavaVarieties.entries) {
    final v = entry.value;
    double score = 100.0;
    final Map<String, String> advice = {};

    if (avgData.ph < v.minPh) {
      final deficit = ((v.minPh - avgData.ph) / v.minPh).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['ph'] = 'pH ต่ำเกินไป (${avgData.ph.toStringAsFixed(1)} / ต้องการ ≥ ${v.minPh})';
    } else if (avgData.ph > v.maxPh) {
      final excess = ((avgData.ph - v.maxPh) / v.maxPh).clamp(0.0, 1.0);
      score -= 25 * excess;
      advice['ph'] = 'pH สูงเกินไป (${avgData.ph.toStringAsFixed(1)} / ต้องการ ≤ ${v.maxPh})';
    }
    if (avgData.nitrogen < v.minN) {
      final deficit = ((v.minN - avgData.nitrogen) / v.minN).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['nitrogen'] = 'N ต่ำ (${avgData.nitrogen.toStringAsFixed(0)} / ต้องการ ≥ ${v.minN})';
    }
    if (avgData.phosphorus < v.minP) {
      final deficit = ((v.minP - avgData.phosphorus) / v.minP).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['phosphorus'] = 'P ต่ำ (${avgData.phosphorus.toStringAsFixed(0)} / ต้องการ ≥ ${v.minP})';
    }
    if (avgData.potassium < v.minK) {
      final deficit = ((v.minK - avgData.potassium) / v.minK).clamp(0.0, 1.0);
      score -= 25 * deficit;
      advice['potassium'] = 'K ต่ำ (${avgData.potassium.toStringAsFixed(0)} / ต้องการ ≥ ${v.minK})';
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
