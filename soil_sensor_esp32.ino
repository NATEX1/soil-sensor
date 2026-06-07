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
#include <TinyGPS++.h>

// --- Pin definitions ---
#define MAX485_DE_RE 4
#define RX_PIN 16
#define TX_PIN 17
#define GPS_RX_PIN 32
#define GPS_TX_PIN 33

// --- OLED ---
Adafruit_SSD1306 display(128, 64, &Wire, -1);

HardwareSerial RS485Serial(2);
HardwareSerial gpsSerial(1);
TinyGPSPlus gps;

ModbusMaster node;
WebServer server(80);

// --- BLE UUIDs ---
#define SERVICE_UUID        "b7185de0-2c63-4c74-8c21-f857dc3fb3eb"
#define CHARACTERISTIC_UUID "229b07fd-7823-4cbe-814c-b08dcca03572"

NimBLEServer* pServer = NULL;
NimBLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

String lastJsonData = "{}";
unsigned long previousMillis = 0;
const long interval = 3000;

// --- RS485 control ---
void preTransmission() { digitalWrite(MAX485_DE_RE, 1); }
void postTransmission() { digitalWrite(MAX485_DE_RE, 0); }

// --- BLE callbacks ---
class MyCallbacks: public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        deviceConnected = true;
    }
    void onDisconnect(NimBLEServer* pServer) {
        deviceConnected = false;
        delay(100);
        NimBLEDevice::startAdvertising();
    }
};

void setup() {
    Serial.begin(115200);

    gpsSerial.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);

    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        Serial.println("OLED Error");
    }
    display.clearDisplay();
    display.setTextColor(WHITE);
    display.setTextSize(1);
    display.setCursor(0, 10);
    display.println("System Starting...");
    display.display();

    // --- WiFi Manager ---
    display.clearDisplay();
    display.setCursor(0, 10);
    display.println("Starting WiFi...");
    display.display();

    WiFiManager wm;
    wm.setMenu({ "wifi", "exit" });
    wm.setConfigPortalTimeout(180);

    display.clearDisplay();
    display.setCursor(0, 10);
    display.println("Connect WiFi to:");
    display.println("SoilSensor_Setup");
    display.display();

    bool res = wm.autoConnect("SoilSensor_Setup");
    if (!res) {
        Serial.println("WiFi not connected — running in AP/BLE mode");
    } else {
        Serial.println("WiFi connected!");
    }

    // --- Web server ---
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

    if (WiFi.status() == WL_CONNECTED) {
        if (MDNS.begin("soilsensor")) {
            MDNS.addService("http", "tcp", 80);
        }
    }

    // --- BLE ---
    display.clearDisplay();
    display.setCursor(0, 10);
    display.println("Starting BLE...");
    display.display();

    NimBLEDevice::init("SoilSensor");
    NimBLEDevice::setMTU(512);
    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new MyCallbacks());

    NimBLEService* pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );
    pService->start();

    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setName("SoilSensor");
    pAdvertising->enableScanResponse(true);
    pAdvertising->start();

    // --- RS485 ---
    pinMode(MAX485_DE_RE, OUTPUT);
    digitalWrite(MAX485_DE_RE, 0);
    RS485Serial.begin(4800, SERIAL_8N1, RX_PIN, TX_PIN);
    node.begin(1, RS485Serial);
    node.preTransmission(preTransmission);
    node.postTransmission(postTransmission);

    Serial.println("Ready! System Online.");
}

void loop() {
    server.handleClient();

    // --- Read GPS (capped at 200 bytes per loop to avoid blocking) ---
    int gpsCap = 200;
    while (gpsSerial.available() > 0 && gpsCap-- > 0) {
        gps.encode(gpsSerial.read());
    }

    // --- Timed sensor read (every 3s) ---
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
        previousMillis = currentMillis;

        // Read NPK sensor
        uint8_t result = node.readHoldingRegisters(0x0000, 7);
        double n = 0, p = 0, k = 0, ph = 0, moisture = 0, temp = 0, ec = 0;
        if (result == node.ku8MBSuccess) {
            moisture = node.getResponseBuffer(0) / 10.0;
            temp     = node.getResponseBuffer(1) / 10.0;
            ec       = node.getResponseBuffer(2);
            ph       = node.getResponseBuffer(3) / 10.0;
            n        = node.getResponseBuffer(4);
            p        = node.getResponseBuffer(5);
            k        = node.getResponseBuffer(6);
        }

        double lat = 0.0, lng = 0.0;
        int sat = 0;
        if (gps.location.isValid()) {
            lat = gps.location.lat();
            lng = gps.location.lng();
            sat = gps.satellites.value();
        }

        StaticJsonDocument<300> doc;
        doc["n"] = n;
        doc["p"] = p;
        doc["k"] = k;
        doc["ph"] = ph;
        doc["moisture"] = moisture;
        doc["temp"] = temp;
        doc["ec"] = ec;
        doc["lat"] = lat;
        doc["lng"] = lng;
        doc["sat"] = sat;

        String jsonString;
        serializeJson(doc, jsonString);
        lastJsonData = jsonString;

        if (deviceConnected) {
            pCharacteristic->setValue(jsonString.c_str());
            pCharacteristic->notify();
        }

        // --- OLED display ---
        display.clearDisplay();
        display.setCursor(0, 0);
        display.print("BLE:");
        display.print(deviceConnected ? "CONN " : "WAIT ");

        display.setCursor(65, 0);
        if (WiFi.status() == WL_CONNECTED) {
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
        display.printf("Temp:%.1fC EC:%.0f S:%d", temp, ec, sat);
        display.display();
    }
}
