# CreepyEyes Firmware

Firmware for the servo-driven CreepyEyes glasses.

This firmware runs on the Seeed Studio XIAO ESP32-C3 installed on each pair of CreepyEyes and is responsible for:

- BLE advertising and secure connection handling
- receiving commands from the CreepyEyes iPhone app
- servo motion control
- blink / wink behavior
- Independent Creepy mode
- Coordinated Creepy mode
- per-creep servo calibration
- branded creep identity via `CREEP_NAME`

The iPhone app acts as the controller/orchestrator, while the firmware owns the actual eye movement and calibration logic.

---

## Current Hardware

The current CreepyEyes build uses:

- Seeed Studio XIAO ESP32-C3
- 2x micro servos
- LEFT servo on `D4`
- RIGHT servo on `D5`
- 1S LiPo battery
- 5V boost converter for servo power
- shared ground between controller and servo power rail

Servo orientation is defined while looking **at the glasses from the front**:

- `D4` = LEFT side
- `D5` = RIGHT side

---

## Current Firmware

The production firmware is shared across the entire Creep Fleet.

Each creep runs the same `.ino` file.

Per-creep differences are handled through:

- `CREEP_NAME`
- local BLE passcode configuration
- calibration values selected by creep name inside the firmware

Current named Creeps include:

- KUATO
- IGOR
- GOLLUM

Future Creeps such as FESTER can be added by adding a new calibration block for that name.

---

## Arduino Environment

Current development environment:

- Arduino IDE
- Board package:
  - `esp32 by Espressif Systems`
- Board:
  - `XIAO_ESP32C3`
- Servo library:
  - `ESP32Servo`
- Serial Monitor:
  - `115200 baud`

---

## BLE Protocol

All Creeps share the same BLE service and characteristic UUIDs.

Each creep advertises using its configured `CREEP_NAME`.

The iPhone app can connect to one or multiple Creeps and route commands individually or to the fleet.

### Current Commands

```text
L:<speed>
R:<speed>
B:<transition interval>:<speed>
I:<transition interval>:<minimum speed>:<maximum speed>
C:<transition interval>:<minimum speed>:<maximum speed>:<seed>
S