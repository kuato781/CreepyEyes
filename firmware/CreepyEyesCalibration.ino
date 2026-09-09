#include <ESP32Servo.h>

Servo leftEye;
Servo rightEye;

// Viewed from FRONT of glasses
const int LEFT_SERVO_PIN  = D4;
const int RIGHT_SERVO_PIN = D5;

int leftPos  = 90;
int rightPos = 90;

char selectedEye = 'L';

void printStatus() {
  Serial.print("Selected: ");
  Serial.print(selectedEye);

  Serial.print("   Left=");
  Serial.print(leftPos);

  Serial.print("   Right=");
  Serial.println(rightPos);
}

void setup() {
  Serial.begin(115200);

  leftEye.attach(LEFT_SERVO_PIN, 500, 2500);
  rightEye.attach(RIGHT_SERVO_PIN, 500, 2500);

  delay(500);

  leftEye.write(leftPos);
  rightEye.write(rightPos);

  Serial.println();
  Serial.println("=== Creepy Eyes Initial Calibration ===");
  Serial.println("L = select LEFT eye");
  Serial.println("R = select RIGHT eye");
  Serial.println("+ = increase selected servo position by 1");
  Serial.println("- = decrease selected servo position by 1");
  Serial.println("P = print current positions");
  Serial.println();

  printStatus();
}

void loop() {
  if (Serial.available()) {
    char c = Serial.read();

    if (c == 'L' || c == 'l') {
      selectedEye = 'L';
      Serial.println("LEFT selected");
    }

    else if (c == 'R' || c == 'r') {
      selectedEye = 'R';
      Serial.println("RIGHT selected");
    }

    else if (c == '+') {
      if (selectedEye == 'L') {
        leftPos++;
        leftEye.write(leftPos);
      } else {
        rightPos++;
        rightEye.write(rightPos);
      }

      printStatus();
    }

    else if (c == '-') {
      if (selectedEye == 'L') {
        leftPos--;
        leftEye.write(leftPos);
      } else {
        rightPos--;
        rightEye.write(rightPos);
      }

      printStatus();
    }

    else if (c == 'P' || c == 'p') {
      printStatus();
    }
  }
}
