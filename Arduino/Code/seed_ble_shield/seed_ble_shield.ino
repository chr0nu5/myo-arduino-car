
#include <SoftwareSerial.h>   //Software Serial Port
#define RxD 2
#define TxD 3

int leftMotor1 = 6;
int leftMotor2 = 7;
int leftEnablePin = 9;

int rightMotor1 = 4;
int rightMotor2 = 5;
int rightEnablePin = 8;

String inData;
SoftwareSerial BLE(RxD,TxD);
 
void setup() { 
  pinMode(RxD, INPUT);
  pinMode(TxD, OUTPUT);
  pinMode(13,OUTPUT);
  BLE.begin(9600);
  BLE.print("AT+CLEAR");
  BLE.print("AT+ROLE0");
  BLE.print("AT+SAVE1");
  
  pinMode(leftMotor1, OUTPUT);
  pinMode(leftMotor2, OUTPUT);
  pinMode(leftEnablePin, OUTPUT);
  
  analogWrite(leftEnablePin, 255);
  analogWrite(rightEnablePin, 255);
  
}

void off(){
  digitalWrite(leftMotor1, LOW);
  digitalWrite(leftMotor2, LOW);
  digitalWrite(rightMotor1, LOW);
  digitalWrite(rightMotor2, LOW);
}

void front(){
  
  digitalWrite(leftMotor1, LOW);
  digitalWrite(leftMotor2, HIGH);
  digitalWrite(rightMotor1, HIGH);
  digitalWrite(rightMotor2, LOW);
}

void back(){
  
  digitalWrite(leftMotor1, HIGH);
  digitalWrite(leftMotor2, LOW);
  digitalWrite(rightMotor1, LOW);
  digitalWrite(rightMotor2, HIGH);
}

void right(){
  
  digitalWrite(leftMotor1, LOW);
  digitalWrite(leftMotor2, HIGH);
  digitalWrite(rightMotor1, LOW);
  digitalWrite(rightMotor2, LOW);
}

void left(){
  
  digitalWrite(leftMotor1, LOW);
  digitalWrite(leftMotor2, LOW);
  digitalWrite(rightMotor1, HIGH);
  digitalWrite(rightMotor2, LOW);
}

void useMessage(String msg) {
  if (msg == "rest") {
    off();
  }
  if (msg == "fist") {
    front();
  }
  if (msg == "spread") {
    back();
  }
  if (msg == "wavein") {
    right();
  }
  if (msg == "waveout") {
    left();
  }
}

void loop() {
  //front();
  while ( BLE.available() ) {
     delay(3);
     char c = BLE.read();
     inData += c;
     if (inData.length() >0) {
      Serial.println(inData);
      useMessage(inData);
     }
  }
  inData = "";
}
