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
