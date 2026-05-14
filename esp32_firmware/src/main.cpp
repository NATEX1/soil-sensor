#include <ModbusMaster.h>
#include <NimBLEDevice.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ESPmDNS.h>
#include <WiFiManager.h>

// --- ตั้งค่าขา Pin ---
#define MAX485_DE_RE 4
#define RX_PIN 16
#define TX_PIN 17

// ข้อมูล WiFi เดิมจะถูกลบออก (WiFiManager จะจัดการให้แทน)

// --- ตั้งค่าจอ OLED ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);
HardwareSerial RS485Serial(2);
ModbusMaster node;
WebServer server(80); 

// --- UUID บลูทูธ ---
#define SERVICE_UUID        "b7185de0-2c63-4c74-8c21-f857dc3fb3eb"
#define CHARACTERISTIC_UUID "229b07fd-7823-4cbe-814c-b08dcca03572"

NimBLEServer* pServer = NULL;
NimBLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// --- ข้อมูลเซนเซอร์และตัวจับเวลา ---
String lastJsonData = "{}";
unsigned long previousMillis = 0; // 🌟 ตัวแปรจับเวลาแทน delay
const long interval = 3000;       // 🌟 ให้อ่านเซนเซอร์ทุก 3 วินาที

// --- ฟังก์ชันควบคุม RS485 ---
void preTransmission() { digitalWrite(MAX485_DE_RE, 1); }
void postTransmission() { digitalWrite(MAX485_DE_RE, 0); }

// --- Callbacks ดักจับ Bluetooth ---
class MyCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) { deviceConnected = true; }
    void onDisconnect(NimBLEServer* pServer) { 
        deviceConnected = false; 
        NimBLEDevice::startAdvertising(); 
    }
};

void setup() {
  Serial.begin(115200);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED Error");
  }
  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.setCursor(0, 10);
  display.println("System Starting...");
  display.display();

  display.clearDisplay();
  display.setCursor(0, 10);
  display.println("Starting WiFi...");
  display.display();

  WiFiManager wm;
  
  // ตั้งเวลาให้รอคนเชื่อมต่อหน้าเว็บ 3 นาที (180 วิ) ถ้าไม่ตั้งค่าให้รันต่อ
  wm.setConfigPortalTimeout(180);

  // สั่งให้หน้าจอแสดงบอกคนใช้ให้ต่อ WiFi เพื่อตั้งค่า
  display.clearDisplay();
  display.setCursor(0, 10);
  display.println("Connect WiFi to:");
  display.println("SoilSensor_Setup");
  display.display();

  // ฟังก์ชันหลัก: พยายามต่อ WiFi เดิม ถ้าต่อไม่ได้ จะปล่อย WiFi ชื่อ "SoilSensor_Setup"
  bool res = wm.autoConnect("SoilSensor_Setup");

  if(!res) {
    Serial.println("Failed to connect or hit timeout");
    // ไม่เป็นไร ปล่อยผ่านไปทำงานแบบออฟไลน์ด้วยบลูทูธแทน
  } else {
    // ถ้าต่อสำเร็จ
    Serial.println("WiFi connected!");
  }

  // ตั้งค่า Web Server 
  server.on("/api/sensor", HTTP_GET, []() {
    server.send(200, "application/json", lastJsonData);
  });
  
  server.on("/", HTTP_GET, []() {
    server.send(200, "text/plain", "SoilSensor OK");
  });
  
  server.on("/ping", HTTP_GET, []() {
    server.send(200, "application/json", "{\"status\":\"ok\",\"device\":\"SoilSensor\"}");
  });

  server.begin();

  if (!MDNS.begin("soilsensor")) {
    Serial.println("MDNS Error!");
  } else {
    MDNS.addService("http", "tcp", 80);
  }

  display.clearDisplay();
  display.setCursor(0, 10);
  display.println("Starting BLE...");
  display.display();

  NimBLEDevice::init("SoilSensor");
  NimBLEDevice::setMTU(512); 
  pServer = NimBLEDevice::createServer();
  pServer->setCallbacks(new MyCallbacks());
  
  NimBLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
                    );
  pService->start();
  
  NimBLEAdvertising *pAdvertising = NimBLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setName("SoilSensor"); 
  pAdvertising->enableScanResponse(true); 
  pAdvertising->start();

  pinMode(MAX485_DE_RE, OUTPUT);
  digitalWrite(MAX485_DE_RE, 0);
  RS485Serial.begin(4800, SERIAL_8N1, RX_PIN, TX_PIN);
  node.begin(1, RS485Serial);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);

  Serial.println("Ready! System Online.");
}

void loop() {
  // 🌟 1. ให้ Web Server ทำงานตลอดเวลา ห้ามโดนบล็อกเด็ดขาด 🌟
  server.handleClient();
  
  // อัปเดตสถานะการเชื่อมต่อบลูทูธตลอดเวลา
  deviceConnected = (pServer->getConnectedCount() > 0);

  // 🌟 2. ใช้การจับเวลาแทน Delay (จะทำบรรทัดในนี้แค่ทุกๆ 3 วินาที) 🌟
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    // อ่านค่าเซนเซอร์
    uint8_t result = node.readHoldingRegisters(0x0000, 7);
    double n=0, p=0, k=0, ph=0, moisture=0, temp=0, ec=0;

    if (result == node.ku8MBSuccess) {
      moisture = node.getResponseBuffer(0) / 10.0;
      temp     = node.getResponseBuffer(1) / 10.0;
      ec       = (double)node.getResponseBuffer(2);
      ph       = node.getResponseBuffer(3) / 10.0;
      n        = (double)node.getResponseBuffer(4);
      p        = (double)node.getResponseBuffer(5);
      k        = (double)node.getResponseBuffer(6);
    }

    // สร้าง JSON
    StaticJsonDocument<200> doc; 
    doc["n"] = n;
    doc["p"] = p;
    doc["k"] = k;
    doc["ph"] = ph;
    doc["moisture"] = moisture;
    doc["temp"] = temp;
    doc["ec"] = ec;

    String jsonString;
    serializeJson(doc, jsonString);
    lastJsonData = jsonString; // เก็บไว้ให้ WiFi ดึงไปใช้

    // ส่งข้อมูลผ่าน Bluetooth (ถ้าเชื่อมต่ออยู่)
    if (deviceConnected) {
      pCharacteristic->setValue(jsonString.c_str());
      pCharacteristic->notify();
    }
    
    // --- แสดงผลจอ OLED ---
    display.clearDisplay();
    display.setCursor(0, 0);
    display.print("BLE:"); 
    display.print(deviceConnected ? "CONN " : "WAIT ");
    
    display.setCursor(65, 0);
    if(WiFi.status() == WL_CONNECTED) {
      display.print("IP:");
      display.print(WiFi.localIP().toString().substring(WiFi.localIP().toString().lastIndexOf('.') + 1));
    } else {
      display.print("AP:4.1"); 
    }
    
    display.setCursor(0, 18);
    display.printf("N:%.0f P:%.0f K:%.0f", n, p, k);
    display.setCursor(0, 33);
    display.printf("pH:%.1f Moist:%.1f%%", ph, moisture);
    display.setCursor(0, 48);
    display.printf("Temp:%.1fC EC:%.0f", temp, ec);
    display.display();
  }
}