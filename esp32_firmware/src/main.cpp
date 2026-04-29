#include <ModbusMaster.h>
#include <NimBLEDevice.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ESPmDNS.h>

// --- ตั้งค่าขา Pin ---
#define MAX485_DE_RE 4
#define RX_PIN 16
#define TX_PIN 17

// --- ข้อมูล WiFi ---
const char* ssid     = "akkalak-2.4G"; 
const char* password = "0902238116";

// --- ตั้งค่า AP Mode (สำหรับใช้งานนอกสถานที่) ---
const char* ap_ssid = "SoilSensor_WiFi";
const char* ap_pass = "12345678";

// --- ตั้งค่าจอ OLED ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);
HardwareSerial RS485Serial(2);
ModbusMaster node;
WebServer server(80); // 🌟 เริ่มต้น Web Server ที่พอร์ต 80

// --- UUID บลูทูธ ---
#define SERVICE_UUID        "b7185de0-2c63-4c74-8c21-f857dc3fb3eb"
#define CHARACTERISTIC_UUID "229b07fd-7823-4cbe-814c-b08dcca03572"

NimBLEServer* pServer = NULL;
NimBLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// --- ฟังก์ชันควบคุม RS485 ---
void preTransmission() { digitalWrite(MAX485_DE_RE, 1); }
void postTransmission() { digitalWrite(MAX485_DE_RE, 0); }

// --- ข้อมูลเซนเซอร์แชร์กันระหว่าง BLE และ WiFi ---
String lastJsonData = "{}";

// --- Callbacks ดักจับ Bluetooth ---
class MyCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) { 
        deviceConnected = true; 
    }
    void onDisconnect(NimBLEServer* pServer) { 
        deviceConnected = false; 
        NimBLEDevice::startAdvertising(); 
    }
};

void setup() {
  Serial.begin(115200);

  // 1. เริ่มจอ OLED
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED Error");
  }
  display.clearDisplay();
  display.setTextColor(WHITE);
  display.setTextSize(1);
  display.setCursor(0, 10);
  display.println("System Starting...");
  display.display();

  // 2. 🌟 ตั้งค่า WiFi (AP + STA)
  display.clearDisplay();
  display.setCursor(0, 10);
  display.println("Starting WiFi...");
  display.display();

  WiFi.disconnect(true); 
  delay(500);
  
  // 🌟 เปิดทั้งโหมดต่อ Router และโหมดปล่อย WiFi เอง
  WiFi.mode(WIFI_AP_STA); 
  WiFi.softAP(ap_ssid, ap_pass);
  WiFi.begin(ssid, password);
  
  Serial.println("WiFi AP: " + String(ap_ssid));
  Serial.print("Connecting to STA");
  
  int wifi_attempts = 0;
  // ลดเวลารอเหลือ 5 วินาที (10 * 500ms) เพื่อไม่ให้ค้างนานเมื่ออยู่นอกสถานที่
  while (WiFi.status() != WL_CONNECTED && wifi_attempts < 10) {
    delay(500);
    Serial.print(".");
    wifi_attempts++;
  }

  if(WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi STA Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\nWiFi STA Timeout! Using AP Mode.");
  }

  // 🌟 ตั้งค่า Web Server 🌟
  server.on("/api/sensor", HTTP_GET, []() {
    server.send(200, "application/json", lastJsonData);
  });
  
  // 🌟 เพิ่มสำหรับการสแกนหาอุปกรณ์ (ดักทางแอป)
  server.on("/", HTTP_GET, []() {
    server.send(200, "text/plain", "SoilSensor OK");
  });
  
  server.on("/ping", HTTP_GET, []() {
    server.send(200, "application/json", "{\"status\":\"ok\",\"device\":\"SoilSensor\"}");
  });

  server.begin();

  // 🌟 ตั้งค่า mDNS ค้นหาผ่านชื่อ "soilsensor.local"
  if (!MDNS.begin("soilsensor")) {
    Serial.println("Error setting up MDNS responder!");
  } else {
    MDNS.addService("http", "tcp", 80);
    Serial.println("mDNS responder started: soilsensor.local");
  }

  // 3. เริ่มระบบ Bluetooth NimBLE
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

  // 4. เริ่มระบบ RS485 เซนเซอร์
  pinMode(MAX485_DE_RE, OUTPUT);
  digitalWrite(MAX485_DE_RE, 0);
  RS485Serial.begin(4800, SERIAL_8N1, RX_PIN, TX_PIN);
  node.begin(1, RS485Serial);
  node.preTransmission(preTransmission);
  node.postTransmission(postTransmission);

  Serial.println("\nReady! System Online.");
}

void loop() {
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
  lastJsonData = jsonString; // เก็บไว้ให้ WiFi ดึง

  // อัปเดตสถานะการเชื่อมต่อบลูทูธ
  deviceConnected = (pServer->getConnectedCount() > 0);

  // ส่งข้อมูลผ่าน Bluetooth (ถ้าเชื่อมต่ออยู่)
  if (deviceConnected) {
    pCharacteristic->setValue(jsonString.c_str());
    pCharacteristic->notify();
  }
  
  // จัดการ HTTP Request
  server.handleClient();

  // --- แสดงผลจอ OLED ---
  display.clearDisplay();
  
  // บรรทัดบนสุด: สถานะ BLE และ WiFi
  display.setCursor(0, 0);
  display.print("BLE:"); 
  display.print(deviceConnected ? "CONN " : "WAIT ");
  
  display.setCursor(65, 0);
  if(WiFi.status() == WL_CONNECTED) {
    display.print("IP:");
    display.print(WiFi.localIP().toString().substring(WiFi.localIP().toString().lastIndexOf('.') + 1));
  } else {
    // แสดงสถานะ AP เมื่อไม่ได้ต่อ Router
    display.print("AP:4.1"); 
  }
  
  // ค่าเซนเซอร์
  display.setCursor(0, 18);
  display.printf("N:%.0f P:%.0f K:%.0f", n, p, k);
  display.setCursor(0, 33);
  display.printf("pH:%.1f Moist:%.1f%%", ph, moisture);
  display.setCursor(0, 48);
  display.printf("Temp:%.1fC EC:%.0f", temp, ec);
  
  display.display();
  
  delay(3000); 
}