#include <ESP32Servo.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLESecurity.h>
#include "secrets.h"

Servo leftEye;
Servo rightEye;

// ==================================================
// DEVICE SETTINGS
// ==================================================

const char* DEVICE_NAME = CREEP_NAME;
const uint32_t BLE_PASSCODE = FLEET_PASSCODE;

// Servo mapping is ALWAYS defined while looking AT
// the glasses from the FRONT.
const int LEFT_SERVO_PIN  = D4;
const int RIGHT_SERVO_PIN = D5;

// ==================================================
// CALIBRATION
//
// Selected automatically from CREEP_NAME.
//
// This prevents accidentally flashing GOLLUM's
// calibration into KUATO, etc.
// ==================================================

int LEFT_OPEN;
int LEFT_CLOSED;

int RIGHT_OPEN;
int RIGHT_CLOSED;

void configureCalibration() {

  String name = DEVICE_NAME;
  name.toUpperCase();

  if (name == "KUATO") {

    LEFT_OPEN    = 130;
    LEFT_CLOSED  = 67;

    RIGHT_OPEN   = 76;
    RIGHT_CLOSED = 115;

    Serial.println("Calibration: KUATO");
  }

  else if (name == "IGOR") {

    LEFT_OPEN    = 117;
    LEFT_CLOSED  = 69;

    RIGHT_OPEN   = 74;
    RIGHT_CLOSED = 110;

    Serial.println("Calibration: IGOR");
  }

  else if (name == "GOLLUM") {

    LEFT_OPEN    = 116;
    LEFT_CLOSED  = 74;

    RIGHT_OPEN   = 85;
    RIGHT_CLOSED = 129;

    Serial.println("Calibration: GOLLUM");
  }

  else {

    // Unknown future creep.
    //
    // KUATO values are used only as a fallback.
    // Add the new creep's calibration above before
    // putting it into production.

    Serial.println();
    Serial.println("********************************");
    Serial.println("WARNING: UNKNOWN CREEP NAME");
    Serial.println("Using KUATO calibration fallback");
    Serial.println("********************************");
    Serial.println();

    LEFT_OPEN    = 130;
    LEFT_CLOSED  = 67;

    RIGHT_OPEN   = 76;
    RIGHT_CLOSED = 115;
  }
}

// ==================================================
// SHARED CREEPY EYES BLE PROTOCOL
// Keep these UUIDs the same on every pair.
// ==================================================

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ==================================================
// V2 FACTORY DEFAULTS
//
// These mirror the iPhone app defaults.
// ==================================================

const float DEFAULT_WINK_SPEED = 1.0;

const float DEFAULT_BLINK_INTERVAL = 3.0;
const float DEFAULT_BLINK_SPEED = 1.0;

const float DEFAULT_CREEPY_INTERVAL = 1.0;
const float DEFAULT_CREEPY_MIN_SPEED = 0.5;
const float DEFAULT_CREEPY_MAX_SPEED = 1.5;

// ==================================================
// MODES
// ==================================================

enum Mode {

  IDLE,

  BLINK_MODE,

  INDEPENDENT_CREEPY_MODE,

  COORDINATED_CREEPY_MODE
};

Mode currentMode = IDLE;

// ==================================================
// MOTION STATES
// ==================================================

enum Motion {

  NONE,

  BOTH_CLOSING,
  BOTH_CLOSED,
  BOTH_OPENING,

  LEFT_CLOSING,
  LEFT_CLOSED_STATE,
  LEFT_OPENING,

  RIGHT_CLOSING,
  RIGHT_CLOSED_STATE,
  RIGHT_OPENING
};

Motion motion = NONE;

unsigned long motionStarted = 0;
unsigned long nextAction = 0;

// ==================================================
// BASE MOTION TIMING
//
// Speed 1.0 = these exact timings.
//
// Speed 2.0 = twice as fast.
// Speed 0.5 = half as fast.
// ==================================================

const unsigned long NORMAL_CLOSE_TIME  = 180;
const unsigned long NORMAL_CLOSED_TIME = 100;
const unsigned long NORMAL_OPEN_TIME   = 240;

const unsigned long RESET_SETTLE_TIME = 120;

unsigned long activeCloseTime  = NORMAL_CLOSE_TIME;
unsigned long activeClosedTime = NORMAL_CLOSED_TIME;
unsigned long activeOpenTime   = NORMAL_OPEN_TIME;

// ==================================================
// ACTIVE MODE SETTINGS
// ==================================================

float activeBlinkInterval = DEFAULT_BLINK_INTERVAL;
float activeBlinkSpeed = DEFAULT_BLINK_SPEED;

float activeCreepyInterval = DEFAULT_CREEPY_INTERVAL;
float activeCreepyMinSpeed = DEFAULT_CREEPY_MIN_SPEED;
float activeCreepyMaxSpeed = DEFAULT_CREEPY_MAX_SPEED;

// Dedicated deterministic random state for
// Coordinated Creepy.
//
// Every creep receiving the same seed produces
// the same actions and speeds in the same order.
uint32_t coordinatedRandomState = 1;

// ==================================================
// CURRENT SERVO POSITION
// ==================================================

int leftCurrent = 0;
int rightCurrent = 0;

// ==================================================
// BLE COMMAND QUEUE
// ==================================================

String pendingBLECommand = "";
bool bleCommandReady = false;

// ==================================================
// GENERAL HELPERS
// ==================================================

float clampFloat(
  float value,
  float minimum,
  float maximum
) {

  if (value < minimum) {
    return minimum;
  }

  if (value > maximum) {
    return maximum;
  }

  return value;
}


int interpolateValue(
  int startValue,
  int endValue,
  unsigned long elapsed,
  unsigned long duration
) {

  if (elapsed >= duration) {
    return endValue;
  }

  float progress =
    (float)elapsed /
    (float)duration;

  return startValue +
         (endValue - startValue) *
         progress;
}


void eyesOpen() {

  leftEye.write(LEFT_OPEN);
  rightEye.write(RIGHT_OPEN);

  leftCurrent  = LEFT_OPEN;
  rightCurrent = RIGHT_OPEN;
}

// ==================================================
// COMMAND PARSING HELPERS
// ==================================================

String commandField(
  const String& command,
  int wantedIndex
) {

  int currentIndex = 0;
  int start = 0;

  for (
    int i = 0;
    i <= command.length();
    i++
  ) {

    if (
      i == command.length()
      ||
      command.charAt(i) == ':'
    ) {

      if (currentIndex == wantedIndex) {

        return command.substring(
          start,
          i
        );
      }

      currentIndex++;
      start = i + 1;
    }
  }

  return "";
}


float commandFloat(
  const String& command,
  int index,
  float defaultValue
) {

  String field =
    commandField(
      command,
      index
    );

  if (field.length() == 0) {
    return defaultValue;
  }

  return field.toFloat();
}


uint32_t commandUInt32(
  const String& command,
  int index,
  uint32_t defaultValue
) {

  String field =
    commandField(
      command,
      index
    );

  if (field.length() == 0) {
    return defaultValue;
  }

  return
    (uint32_t)
    strtoul(
      field.c_str(),
      nullptr,
      10
    );
}

// ==================================================
// SPEED ENGINE
// ==================================================

void setMotionSpeed(
  float speedMultiplier
) {

  speedMultiplier =
    clampFloat(
      speedMultiplier,
      0.20,
      3.00
    );

  activeCloseTime =
    max(
      20UL,
      (unsigned long)(
        NORMAL_CLOSE_TIME /
        speedMultiplier
      )
    );

  activeClosedTime =
    max(
      20UL,
      (unsigned long)(
        NORMAL_CLOSED_TIME /
        speedMultiplier
      )
    );

  activeOpenTime =
    max(
      20UL,
      (unsigned long)(
        NORMAL_OPEN_TIME /
        speedMultiplier
      )
    );
}

// ==================================================
// START MOTIONS
// ==================================================

void startBothBlink() {

  motion = BOTH_CLOSING;
  motionStarted = millis();
}


void startLeftWink() {

  motion = LEFT_CLOSING;
  motionStarted = millis();
}


void startRightWink() {

  motion = RIGHT_CLOSING;
  motionStarted = millis();
}

// ==================================================
// MOTION ENGINE
// ==================================================

void updateMotion() {

  unsigned long now =
    millis();

  unsigned long elapsed =
    now - motionStarted;

  switch (motion) {

    case BOTH_CLOSING:

      leftCurrent =
        interpolateValue(
          LEFT_OPEN,
          LEFT_CLOSED,
          elapsed,
          activeCloseTime
        );

      rightCurrent =
        interpolateValue(
          RIGHT_OPEN,
          RIGHT_CLOSED,
          elapsed,
          activeCloseTime
        );

      leftEye.write(leftCurrent);
      rightEye.write(rightCurrent);

      if (
        elapsed >=
        activeCloseTime
      ) {

        leftEye.write(
          LEFT_CLOSED
        );

        rightEye.write(
          RIGHT_CLOSED
        );

        motion =
          BOTH_CLOSED;

        motionStarted =
          now;
      }

      break;


    case BOTH_CLOSED:

      if (
        elapsed >=
        activeClosedTime
      ) {

        motion =
          BOTH_OPENING;

        motionStarted =
          now;
      }

      break;


    case BOTH_OPENING:

      leftCurrent =
        interpolateValue(
          LEFT_CLOSED,
          LEFT_OPEN,
          elapsed,
          activeOpenTime
        );

      rightCurrent =
        interpolateValue(
          RIGHT_CLOSED,
          RIGHT_OPEN,
          elapsed,
          activeOpenTime
        );

      leftEye.write(
        leftCurrent
      );

      rightEye.write(
        rightCurrent
      );

      if (
        elapsed >=
        activeOpenTime
      ) {

        eyesOpen();

        motion = NONE;
      }

      break;


    case LEFT_CLOSING:

      leftCurrent =
        interpolateValue(
          LEFT_OPEN,
          LEFT_CLOSED,
          elapsed,
          activeCloseTime
        );

      leftEye.write(
        leftCurrent
      );

      if (
        elapsed >=
        activeCloseTime
      ) {

        leftEye.write(
          LEFT_CLOSED
        );

        motion =
          LEFT_CLOSED_STATE;

        motionStarted =
          now;
      }

      break;


    case LEFT_CLOSED_STATE:

      if (
        elapsed >=
        activeClosedTime
      ) {

        motion =
          LEFT_OPENING;

        motionStarted =
          now;
      }

      break;


    case LEFT_OPENING:

      leftCurrent =
        interpolateValue(
          LEFT_CLOSED,
          LEFT_OPEN,
          elapsed,
          activeOpenTime
        );

      leftEye.write(
        leftCurrent
      );

      if (
        elapsed >=
        activeOpenTime
      ) {

        leftEye.write(
          LEFT_OPEN
        );

        leftCurrent =
          LEFT_OPEN;

        motion =
          NONE;
      }

      break;


    case RIGHT_CLOSING:

      rightCurrent =
        interpolateValue(
          RIGHT_OPEN,
          RIGHT_CLOSED,
          elapsed,
          activeCloseTime
        );

      rightEye.write(
        rightCurrent
      );

      if (
        elapsed >=
        activeCloseTime
      ) {

        rightEye.write(
          RIGHT_CLOSED
        );

        motion =
          RIGHT_CLOSED_STATE;

        motionStarted =
          now;
      }

      break;


    case RIGHT_CLOSED_STATE:

      if (
        elapsed >=
        activeClosedTime
      ) {

        motion =
          RIGHT_OPENING;

        motionStarted =
          now;
      }

      break;


    case RIGHT_OPENING:

      rightCurrent =
        interpolateValue(
          RIGHT_CLOSED,
          RIGHT_OPEN,
          elapsed,
          activeOpenTime
        );

      rightEye.write(
        rightCurrent
      );

      if (
        elapsed >=
        activeOpenTime
      ) {

        rightEye.write(
          RIGHT_OPEN
        );

        rightCurrent =
          RIGHT_OPEN;

        motion =
          NONE;
      }

      break;


    case NONE:
      break;
  }
}

// ==================================================
// COORDINATED RANDOM ENGINE
//
// xorshift32 provides a tiny deterministic PRNG.
// Same starting seed = same random sequence.
// ==================================================

uint32_t nextCoordinatedRandom() {

  uint32_t x =
    coordinatedRandomState;

  if (x == 0) {
    x = 0x6D2B79F5;
  }

  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;

  coordinatedRandomState =
    x;

  return x;
}


float coordinatedRandomFloat(
  float minimum,
  float maximum
) {

  uint32_t value =
    nextCoordinatedRandom();

  float normalized =
    (float)value /
    (float)UINT32_MAX;

  return minimum +
         normalized *
         (maximum - minimum);
}


int coordinatedRandomAction() {

  return
    nextCoordinatedRandom() %
    5;
}

// ==================================================
// CREEPY ACTION ENGINE
// ==================================================

void runCreepyAction(
  int action,
  float speed
) {

  setMotionSpeed(speed);

  switch (action) {

    case 0:

      Serial.print(
        "CREEPY: BLINK @ "
      );

      Serial.println(speed);

      startBothBlink();

      break;


    case 1:

      Serial.print(
        "CREEPY: LEFT WINK @ "
      );

      Serial.println(speed);

      startLeftWink();

      break;


    case 2:

      Serial.print(
        "CREEPY: RIGHT WINK @ "
      );

      Serial.println(speed);

      startRightWink();

      break;


    case 3:

      Serial.print(
        "CREEPY: BLINK @ "
      );

      Serial.println(speed);

      startBothBlink();

      break;


    case 4:

      Serial.print(
        "CREEPY: BLINK @ "
      );

      Serial.println(speed);

      startBothBlink();

      break;
  }
}


void runIndependentCreepyAction() {

  int action =
    random(0, 5);

  float speed =
    activeCreepyMinSpeed +
    (
      random(0, 10001) /
      10000.0
    )
    *
    (
      activeCreepyMaxSpeed -
      activeCreepyMinSpeed
    );

  runCreepyAction(
    action,
    speed
  );
}


void runCoordinatedCreepyAction() {

  int action =
    coordinatedRandomAction();

  float speed =
    coordinatedRandomFloat(
      activeCreepyMinSpeed,
      activeCreepyMaxSpeed
    );

  runCreepyAction(
    action,
    speed
  );
}

// ==================================================
// COMMAND HANDLER
// ==================================================

void handleCommand(
  String command
) {

  command.trim();
  command.toUpperCase();

  if (
    command.length() == 0
  ) {
    return;
  }

  Serial.print(
    "COMMAND: "
  );

  Serial.println(
    command
  );

  // Every new command:
  //
  // 1. cancels current mode
  // 2. cancels current motion
  // 3. opens both eyes
  // 4. waits briefly
  // 5. starts new behavior

  currentMode = IDLE;
  motion = NONE;

  eyesOpen();

  delay(
    RESET_SETTLE_TIME
  );

  String opcode =
    commandField(
      command,
      0
    );

  // ==================================================
  // B = BLINK
  //
  // B:<interval>:<speed>
  //
  // B alone still works using defaults.
  // ==================================================

  if (opcode == "B") {

    activeBlinkInterval =
      clampFloat(
        commandFloat(
          command,
          1,
          DEFAULT_BLINK_INTERVAL
        ),
        0.25,
        30.0
      );

    activeBlinkSpeed =
      clampFloat(
        commandFloat(
          command,
          2,
          DEFAULT_BLINK_SPEED
        ),
        0.20,
        3.0
      );

    Serial.print(
      "BLINK MODE interval="
    );

    Serial.print(
      activeBlinkInterval
    );

    Serial.print(
      " speed="
    );

    Serial.println(
      activeBlinkSpeed
    );

    setMotionSpeed(
      activeBlinkSpeed
    );

    currentMode =
      BLINK_MODE;

    nextAction =
      millis();
  }

  // ==================================================
  // I = INDEPENDENT CREEPY
  //
  // I:<interval>:<minSpeed>:<maxSpeed>
  // ==================================================

  else if (opcode == "I") {

    activeCreepyInterval =
      clampFloat(
        commandFloat(
          command,
          1,
          DEFAULT_CREEPY_INTERVAL
        ),
        0.20,
        30.0
      );

    activeCreepyMinSpeed =
      clampFloat(
        commandFloat(
          command,
          2,
          DEFAULT_CREEPY_MIN_SPEED
        ),
        0.20,
        3.0
      );

    activeCreepyMaxSpeed =
      clampFloat(
        commandFloat(
          command,
          3,
          DEFAULT_CREEPY_MAX_SPEED
        ),
        0.20,
        3.0
      );

    if (
      activeCreepyMaxSpeed <
      activeCreepyMinSpeed
    ) {

      float temp =
        activeCreepyMinSpeed;

      activeCreepyMinSpeed =
        activeCreepyMaxSpeed;

      activeCreepyMaxSpeed =
        temp;
    }

    Serial.println(
      "INDEPENDENT CREEPY MODE"
    );

    currentMode =
      INDEPENDENT_CREEPY_MODE;

    nextAction =
      millis();
  }

  // ==================================================
  // C = COORDINATED CREEPY
  //
  // C:<interval>:<minSpeed>:<maxSpeed>:<seed>
  //
  // Every creep gets the same seed from the iPhone.
  // ==================================================

  else if (opcode == "C") {

    activeCreepyInterval =
      clampFloat(
        commandFloat(
          command,
          1,
          DEFAULT_CREEPY_INTERVAL
        ),
        0.20,
        30.0
      );

    activeCreepyMinSpeed =
      clampFloat(
        commandFloat(
          command,
          2,
          DEFAULT_CREEPY_MIN_SPEED
        ),
        0.20,
        3.0
      );

    activeCreepyMaxSpeed =
      clampFloat(
        commandFloat(
          command,
          3,
          DEFAULT_CREEPY_MAX_SPEED
        ),
        0.20,
        3.0
      );

    if (
      activeCreepyMaxSpeed <
      activeCreepyMinSpeed
    ) {

      float temp =
        activeCreepyMinSpeed;

      activeCreepyMinSpeed =
        activeCreepyMaxSpeed;

      activeCreepyMaxSpeed =
        temp;
    }

    coordinatedRandomState =
      commandUInt32(
        command,
        4,
        0x6D2B79F5
      );

    if (
      coordinatedRandomState == 0
    ) {

      coordinatedRandomState =
        0x6D2B79F5;
    }

    Serial.println(
      "COORDINATED CREEPY MODE"
    );

    Serial.print(
      "Seed: "
    );

    Serial.println(
      coordinatedRandomState
    );

    currentMode =
      COORDINATED_CREEPY_MODE;

    nextAction =
      millis();
  }

  // ==================================================
  // L = ONE LEFT WINK
  //
  // L:<speed>
  //
  // Wink interval is NOT used here.
  // It is handled by Performance on the iPhone.
  // ==================================================

  else if (opcode == "L") {

    float speed =
      clampFloat(
        commandFloat(
          command,
          1,
          DEFAULT_WINK_SPEED
        ),
        0.20,
        3.0
      );

    Serial.print(
      "LEFT WINK speed="
    );

    Serial.println(
      speed
    );

    setMotionSpeed(
      speed
    );

    startLeftWink();
  }

  // ==================================================
  // R = ONE RIGHT WINK
  // ==================================================

  else if (opcode == "R") {

    float speed =
      clampFloat(
        commandFloat(
          command,
          1,
          DEFAULT_WINK_SPEED
        ),
        0.20,
        3.0
      );

    Serial.print(
      "RIGHT WINK speed="
    );

    Serial.println(
      speed
    );

    setMotionSpeed(
      speed
    );

    startRightWink();
  }

  // ==================================================
  // S = STOP
  // ==================================================

  else if (opcode == "S") {

    Serial.println(
      "STOP / EYES OPEN"
    );
  }

  // ==================================================
  // RESERVED CALIBRATION COMMANDS
  // ==================================================

  else if (opcode == "SL") {

    Serial.println(
      "SET LEFT CALIBRATION - reserved"
    );
  }

  else if (opcode == "SR") {

    Serial.println(
      "SET RIGHT CALIBRATION - reserved"
    );
  }

  else {

    Serial.print(
      "UNKNOWN COMMAND: "
    );

    Serial.println(
      command
    );
  }
}

// ==================================================
// MODE ENGINE
// ==================================================

void updateMode() {

  if (motion != NONE) {
    return;
  }

  unsigned long now =
    millis();

  if (now < nextAction) {
    return;
  }

  // ==================================================
  // REPEATING BLINK
  // ==================================================

  if (
    currentMode ==
    BLINK_MODE
  ) {

    setMotionSpeed(
      activeBlinkSpeed
    );

    startBothBlink();

    nextAction =
      now +
      (
        unsigned long
      )(
        activeBlinkInterval *
        1000.0
      );
  }

  // ==================================================
  // INDEPENDENT CREEPY
  // ==================================================

  else if (
    currentMode ==
    INDEPENDENT_CREEPY_MODE
  ) {

    runIndependentCreepyAction();

    nextAction =
      now +
      (
        unsigned long
      )(
        activeCreepyInterval *
        1000.0
      );
  }

  // ==================================================
  // COORDINATED CREEPY
  // ==================================================

  else if (
    currentMode ==
    COORDINATED_CREEPY_MODE
  ) {

    runCoordinatedCreepyAction();

    nextAction =
      now +
      (
        unsigned long
      )(
        activeCreepyInterval *
        1000.0
      );
  }
}

// ==================================================
// BLE CALLBACKS
// ==================================================

class CreepyCommandCallbacks :
  public BLECharacteristicCallbacks {

  void onWrite(
    BLECharacteristic *pCharacteristic
  ) override {

    String value =
      pCharacteristic->getValue();

    value.trim();

    if (
      value.length() > 0
    ) {

      pendingBLECommand =
        value;

      bleCommandReady =
        true;
    }
  }
};


class CreepyServerCallbacks :
  public BLEServerCallbacks {

  void onDisconnect(
    BLEServer *pServer
  ) override {

    BLEDevice::startAdvertising();
  }
};

// ==================================================
// BLE SECURITY + SETUP
// ==================================================

void setupBLE() {

  BLEDevice::init(
    DEVICE_NAME
  );

  BLESecurity *pSecurity =
    new BLESecurity();

  pSecurity->setPassKey(
    true,
    BLE_PASSCODE
  );

  // The glasses conceptually "display"
  // the fixed passcode.
  //
  // The iPhone is where the user enters it.

  pSecurity->setCapability(
    ESP_IO_CAP_OUT
  );

  pSecurity->setAuthenticationMode(
    true,   // bonding
    true,   // MITM
    true    // secure connection
  );

  BLEServer *pServer =
    BLEDevice::createServer();

  pServer->setCallbacks(
    new CreepyServerCallbacks()
  );

  pServer->advertiseOnDisconnect(
    true
  );

  BLEService *pService =
    pServer->createService(
      SERVICE_UUID
    );

  uint32_t properties =
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_READ_AUTHEN |
    BLECharacteristic::PROPERTY_WRITE_AUTHEN;

  BLECharacteristic *pCharacteristic =
    pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      properties
    );

  pCharacteristic->setCallbacks(
    new CreepyCommandCallbacks()
  );

  pCharacteristic->setValue(
    "READY"
  );

  pService->start();

  BLEAdvertising *pAdvertising =
    BLEDevice::getAdvertising();

  pAdvertising->addServiceUUID(
    SERVICE_UUID
  );

  pAdvertising->setScanResponse(
    true
  );

  pAdvertising->setMinPreferred(
    0x06
  );

  pAdvertising->setMaxPreferred(
    0x12
  );

  BLEDevice::startAdvertising();

  Serial.print(
    "BLE advertising as: "
  );

  Serial.println(
    DEVICE_NAME
  );

  Serial.print(
    "BLE passcode: "
  );

  Serial.printf(
    "%06u\n",
    BLE_PASSCODE
  );
}

// ==================================================
// SETUP
// ==================================================

void setup() {

  Serial.begin(
    115200
  );

  delay(250);

  Serial.println();
  Serial.println(
    "Configuring Creep..."
  );

  configureCalibration();

  leftEye.attach(
    LEFT_SERVO_PIN,
    500,
    2500
  );

  rightEye.attach(
    RIGHT_SERVO_PIN,
    500,
    2500
  );

  delay(500);

  eyesOpen();

  randomSeed(
    micros()
  );

  setupBLE();

  Serial.println();
  Serial.println(
    "============================"
  );

  Serial.println(
    "       CREEPY EYES V2"
  );

  Serial.println(
    "============================"
  );

  Serial.println();

  Serial.print(
    "Device: "
  );

  Serial.println(
    DEVICE_NAME
  );

  Serial.println();

  Serial.println(
    "B = repeating blink"
  );

  Serial.println(
    "I = independent creepy"
  );

  Serial.println(
    "C = coordinated creepy"
  );

  Serial.println(
    "L = one left wink"
  );

  Serial.println(
    "R = one right wink"
  );

  Serial.println(
    "S = stop / eyes open"
  );

  Serial.println();

  Serial.println(
    "V2 parameter examples:"
  );

  Serial.println(
    "L:1.00"
  );

  Serial.println(
    "R:1.00"
  );

  Serial.println(
    "B:3.00:1.00"
  );

  Serial.println(
    "I:1.00:0.50:1.50"
  );

  Serial.println(
    "C:1.00:0.50:1.50:123456789"
  );

  Serial.println();
}

// ==================================================
// MAIN LOOP
// ==================================================

void loop() {

  // Serial Monitor uses the exact same
  // command parser as BLE.

  if (
    Serial.available()
  ) {

    String command =
      Serial.readStringUntil(
        '\n'
      );

    handleCommand(
      command
    );
  }

  // BLE feeds the same command handler.

  if (
    bleCommandReady
  ) {

    String command =
      pendingBLECommand;

    pendingBLECommand =
      "";

    bleCommandReady =
      false;

    handleCommand(
      command
    );
  }

  updateMotion();
  updateMode();
}
