#include <Arduino.h>
#include <ModbusMaster.h>
#include <NimBLEDevice.h>
#include <ArduinoJson.h>

// การตั้งค่า Pin สำหรับเชื่อมต่อกับ Module MAX485
// แนะนำ: ให้เชื่อมขา RE และ DE ของ MAX485 เข้าด้วยกัน แล้วนำมาเสียบที่ Pin 4 ของ ESP32
#define MAX485_DE_RE      4
#define RX_PIN            16 // เสียบที่ขา RO ของ MAX485
#define TX_PIN            17 // เสียบที่ขา DI ของ MAX485

HardwareSerial RS485Serial(2); // เรียกใช้ UART2 ของ ESP32
ModbusMaster node;

// การตั้งค่า BLE Service ตรงกับ Flutter App
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "abcd1234-ab12-ab12-ab12-abcdef123456"

NimBLEServer* pServer = NULL;
NimBLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// ฟังก์ชันควบคุมทิศทางการรับส่งข้อมูลของ RS485
void preTransmission() {
  digitalWrite(MAX485_DE_RE, 1);
}

void postTransmission() {
  digitalWrite(MAX485_DE_RE, 0);
}

// Callback เฝ้าระวังการเชื่อมต่อ BLE จากแอปมือถือ
class MyServerCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
      deviceConnected = true;
      Serial.println("📱 โทรศัพท์เชื่อมต่อแล้ว");
    }
    void onDisconnect(NimBLEServer* pServer) {
      deviceConnected = false;
      Serial.println("📱 โทรศัพท์ตัดการเชื่อมต่อ - เปิดรับใหม่...");
      NimBLEDevice::startAdvertising();
    }
};

void setupBLE() {
  NimBLEDevice::init("SoilSensor"); // ชื่อนี้แอปมือถือจะสแกนหา
  pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  NimBLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      NIMBLE_PROPERTY::READ |
                      NIMBLE_PROPERTY::NOTIFY
                    );

  pService->start();
  NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  NimBLEDevice::startAdvertising();
  Serial.println("⚡ เริ่มต้น BLE สำเร็จ พร้อมให้แอปสแกน");
}

void setup() {
  Serial.begin(115200);

  // ตั้งค่าขาควบคุม MAX485
  pinMode(MAX485_DE_RE, OUTPUT);
  digitalWrite(MAX485_DE_RE, 0);

  // เริ่มต้นสื่อสารกับเซ็นเซอร์ NPK ด้วย Baud rate 9600 (ค่ามาตรฐานโรงงาน)
  RS485Serial.begin(9600, SERIAL_8N1, RX_PIN, TX_PIN);

  // เริ่มต้นโปรโตคอล Modbus ที่ Slave ID 1 (ค่ามาตรฐานเซ็นเซอร์ NPK ส่วนใหญ่)
  node.begin(1, RS485Serial);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);

  setupBLE();
}

void loop() {
  // หากมีแอปมือถือเชื่อมต่ออยู่ ถึงจะเรียกอ่านค่าจากเซ็นเซอร์ (ช่วยประหยัดแบตเตอรี่)
  if (deviceConnected) {
    uint8_t result;
    
    // ส่งคำสั่งอ่าน Holding Register เริ่มจาก Address 0 ขอจำนวน 7 ตัว
    result = node.readHoldingRegisters(0x0000, 7);
    
    if (result == node.ku8MBSuccess) {
      // นำค่าดิบที่ได้มาแปลงกลับตามหน่วยพื้นฐาน (ตรวจสอบ Manual ถ้ารุ่นที่ซื้อมามีการจัดเรียงแตกต่างออกไป)
      float moisture = node.getResponseBuffer(0) / 10.0;  // ความชื้น %
      float temp     = node.getResponseBuffer(1) / 10.0;  // อุณหภูมิ °C
      float ec       = node.getResponseBuffer(2);         // EC us/cm
      float ph       = node.getResponseBuffer(3) / 10.0;  // pH
      float nitrogen = node.getResponseBuffer(4);         // N mg/kg
      float phosphorus = node.getResponseBuffer(5);       // P mg/kg
      float potassium = node.getResponseBuffer(6);        // K mg/kg

      // สร้างข้อมูลแบบ JSON
      StaticJsonDocument<200> doc;
      doc["ec"] = ec;
      doc["ph"] = ph;
      doc["n"]  = nitrogen;
      doc["p"]  = phosphorus;
      doc["k"]  = potassium;
      doc["moisture"] = moisture;
      doc["temp"] = temp;

      String jsonString;
      serializeJson(doc, jsonString);
      
      Serial.println(jsonString);

      // กระจายเสียงไปยัง Flutter App
      pCharacteristic->setValue(std::string(jsonString.c_str()));
      pCharacteristic->notify();
    } else {
      Serial.print("❌ ยิงคำสั่งอ่านแล้วเซ็นเซอร์ไม่ตอบ กำลังลองใหม่... (รหัสข้อผิดพลาด: ");
      Serial.print(result);
      Serial.println(")");
    }
  }

  // ดีเลย์ 3 วินาทีก่อนอ่านข้อมูลครั้งถัดไป
  delay(3000);
}
