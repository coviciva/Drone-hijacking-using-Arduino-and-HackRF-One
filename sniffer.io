#include <nRF24L01.h>
#include <printf.h>
#include <RF24.h>
#include <RF24_config.h>

#define CE_PIN  8  /// Promijeniti za odgovarajući model Arduina
#define CSN_PIN 7  /// Promijeniti za odgovarajući model Arduina

RF24 radio(CE_PIN, CSN_PIN); 

const char tohex[] = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'};
uint64_t pipe = 0x00AA;

byte buff[32];
byte chan=0;
byte len = 32;
byte addr_len = 2;

void set_nrf(){
  radio.setDataRate(RF24_250KBPS);
  radio.setCRCLength(RF24_CRC_DISABLED);
  radio.setAddressWidth(addr_len);
  radio.setPayloadSize(len);
  radio.setChannel(chan);
  radio.openReadingPipe(1, pipe);
  radio.startListening();  
}

void setup() {
  Serial.begin(2000000);
  printf_begin();
  radio.begin();
  set_nrf();
}

long t1 = 0;
long t2 = 0;
long tr = 0;

void loop() {
  byte in;
   if (Serial.available() >0) {
     in = Serial.read();
     if (in == 'w') {
      chan+=1;
      radio.setChannel(chan);
      Serial.print("\nSet chan: "); 
      Serial.print(chan);
     }
     if (in == 's') {
      chan-=1;
      radio.setChannel(chan);
      Serial.print("\nSet chan: "); 
      Serial.print(chan);
     }
     if (in == 'q') {
     Serial.print("\n"); 
     radio.printDetails();
     }  
   }
  while (radio.available()) {                      
    t2 = t1;
    t1 = micros();
    tr+=1;
    radio.read(&buff, sizeof(buff) );
    Serial.print("\n"); 
    Serial.print(tr);
    Serial.print("\tms: "); 
    Serial.print(millis());
    Serial.print("\tCh: ");
    Serial.print(chan);
    Serial.print("\tGet data: ");
    for (byte i=0; i
      Serial.print(tohex[(byte)buff[i]>>4]);
      Serial.print(tohex[(byte)buff[i]&0x0f]);      
    }    
  }
}
