// Required Libraries
#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include <dht11.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

/* Wifi Connection Information */
#define WIFI_SSID "wifi-name"            // Wi-Fi Name
#define WIFI_PASSWORD "wifi-password"    // Wi-Fi Password

/* Firebase API Key */
#define API_KEY "your-firebase-api-key"

/* RealTime Database URL */
#define DATABASE_URL "your-firebase-realtime-database-link"

/* Created User Email and Password */
#define USER_EMAIL "firebase-authentication-user-email"
#define USER_PASSWORD "firebase-authentication-user-password"

// Define Firebase Data object
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long sendDataPrevMillis = 0;
unsigned long count = 0;

const int AOUTpin = A0;  // Analog output pin
const int DOUTpin = 16;

// DHT11 dht11(2); // DHT11 temperature-humidity sensor connected to D4 pin
int DhtPin = 2;    // We set Digital 2 as DhtPin.
dht11 dht_sensor;  // We create a DHT11 object named dht_sensor.

// Variable definitions for storing data to be saved in the database
float temperature;
float humidity;
int ppm;
int second;
void setup() {

  Serial.begin(115200);

  // We connect to the Wi-Fi here and wait until the device is connected
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  unsigned long ms = millis();
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());
  Serial.println();

  // Firebase configuration is set.
  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  // API key is set
  config.api_key = API_KEY;

  // User login information is set
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  // RTDB (Realtime Database) URL is set
  config.database_url = DATABASE_URL;

  // Callback function is assigned for long-term token generation task
  config.token_status_callback = tokenStatusCallback;

  // BSSL (BearSSL) memory size is set for the FirebaseData object.
  fbdo.setBSSLBufferSize(4096, 1024);

  // Response size for the FirebaseData object is set.
  fbdo.setResponseSize(2048);

  // Firebase library is initialized.
  Firebase.begin(&config, &auth);

  // Settings for the Firebase library are configured.
  Firebase.setDoubleDigits(5);

  // Timeout for server response is set.
  config.timeout.serverResponse = 10 * 1000;

  // Digital pin mode is set
  pinMode(DOUTpin, INPUT); 
  second = Firebase.RTDB.getInt(&fbdo, F("/project/TIME"), &second)*1000;
}

void loop() {

  if (Firebase.ready() && (millis() - sendDataPrevMillis > second || sendDataPrevMillis == 0))  // Data upload every specified interval.
  {
    int chk = dht_sensor.read(DhtPin);

    sendDataPrevMillis = millis();
    ppm = analogRead(AOUTpin);  // Reading CO2 value from the sensor
    Serial.println(ppm);
    temperature = dht_sensor.temperature;  // Reading temperature value from the sensor
    Serial.println(temperature);
    delay(1000);
    humidity = dht_sensor.humidity;  // Reading humidity value from the sensor
    Serial.println(humidity);

    Firebase.RTDB.setFloat(&fbdo, F("/project/TEMPERATURE"), temperature);  // Uploading temperature value to Firebase
    Firebase.RTDB.setFloat(&fbdo, F("/project/HUMIDITY"), humidity);        // Uploading humidity value to Firebase
    Firebase.RTDB.setInt(&fbdo, F("/project/CO2"), ppm);                    // Uploading CO2 value to Firebase
    
    Firebase.RTDB.getInt(&fbdo, F("/project/TIME"), &second);
    second = second*1000;
    Serial.println(second);
    Serial.println();
  }
}
