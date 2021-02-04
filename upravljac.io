#include <nRF24L01.h>
#include <printf.h>
#include <RF24.h>
#include <RF24_config.h>

#define CE_PIN  8
#define CSN_PIN 7

//// syma
uint8_t chan[4] = {25,41,57,73}; 
const char tohex[] = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
uint64_t pipe = 0xa20009890fLL; 

RF24 radio(CE_PIN, CSN_PIN); 
int8_t packet[10];
int joy_raw[7];
byte ch=0;

//// controls
uint8_t throttle = 0;
int8_t rudder = 0;
int8_t elevator = 0;
int8_t aileron = 0;

//// syma checksum
uint8_t checksum(){
    uint8_t sum = packet[0];
    for (int i=1; i < 9; i++) sum ^= packet[i];
    return (sum + 0x55);
}

//// initial
void setup() {
  //set nrf
  radio.begin();
  radio.setDataRate(RF24_250KBPS);
  radio.setCRCLength(RF24_CRC_16);
  radio.setPALevel(RF24_PA_MAX);
  radio.setAutoAck(false);
  radio.setRetries(0,0);
  radio.setAddressWidth(5);
  radio.openWritingPipe(pipe);
  radio.setPayloadSize(10);
  radio.setChannel(25);
  //set joystick
  pinMode(A0, INPUT);
  pinMode(A1, INPUT);
  pinMode(A2, INPUT);
  pinMode(A3, INPUT);
  pinMode(A4, INPUT);
  pinMode(A5, INPUT);
  pinMode(A6, INPUT);
  digitalWrite(A3, HIGH);
  digitalWrite(A4, HIGH);
  digitalWrite(A5, HIGH);
  digitalWrite(A6, HIGH);
  //init default data
  packet[0] = 0x00;
  packet[1] = 0x00;
  packet[2] = 0x00;
  packet[3] = 0x00;
  packet[4] = 0x00;
  packet[5] = 0x40;
  packet[6] = 0x00;
  packet[7] = 0x21;
  packet[8] = 0x00;
  packet[9] = checksum();
}

void read_logitech() {
  joy_raw[0] = analogRead(A0);
  joy_raw[1] = analogRead(A1);
  joy_raw[2] = analogRead(A2);
  joy_raw[3] = !digitalRead(A3);
  joy_raw[4] = !digitalRead(A4);
  joy_raw[5] = !digitalRead(A6);
  joy_raw[6] = !digitalRead(A5);
  //little calibration
  joy_raw[0] = map(joy_raw[0],150, 840, 255, 0)+10;
  joy_raw[0] = constrain(joy_raw[0], 0, 254);
  joy_raw[1] = map(joy_raw[1],140, 830, 0, 255);
  joy_raw[1] = constrain(joy_raw[1], 0, 254);
  joy_raw[2] = map(joy_raw[2],130, 720, 255, 0);
  joy_raw[2] = constrain(joy_raw[2], 0, 254);
}

//// main loop
void loop() {
  read_logitech();
  throttle = joy_raw[2];
  rudder = 64*joy_raw[4] - 64*joy_raw[5];
  elevator = joy_raw[1]-127;
  aileron = joy_raw[0]-127;
  radio.openWritingPipe(pipe);
  ch +=1;
  if (ch>3) ch = 0; 
  radio.setChannel(chan[ch]);      
  packet[0] = throttle;
  if (elevator < 0) packet[1] = abs(elevator) | 0x80; else packet[1] = elevator;
  if (rudder < 0) packet[2] = abs(rudder) | 0x80; else packet[2] = rudder;
  if (aileron < 0) packet[3] = abs(aileron) | 0x80; else packet[3] = aileron;
  packet[4] = 0x00;
  packet[5] = 0x40;
  packet[6] = 0x00;
  packet[7] = 0x21;
  packet[8] = 0x00;
  packet[9] = checksum();
  radio.write( packet, sizeof(packet) );
} 
