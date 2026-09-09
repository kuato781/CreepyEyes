# CreepyEyes Firmware

Firmware for the servo-driven CreepyEyes glasses.

This directory contains both:

- the shared production firmware used by the Creep Fleet
- the calibration sketch used when building or servicing an individual creep

Current firmware files:

```text
CreepyEyes.ino
CreepyEyesCalibration.ino
secrets.example.h
```

---

## Production Firmware

The production firmware is:

```text
CreepyEyes.ino
```

It runs on the Seeed Studio XIAO ESP32-C3 installed on each pair of CreepyEyes and is responsible for:

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

Servo orientation is always defined while looking **at the glasses from the front**:

```text
D4 = LEFT
D5 = RIGHT
```

---

## Shared Fleet Firmware

The same `CreepyEyes.ino` production firmware is used across the entire Creep Fleet.

Per-creep differences are handled through:

- `CREEP_NAME`
- local BLE passcode configuration
- calibration values selected by creep name inside the firmware

Current named Creeps include:

- KUATO
- IGOR
- GOLLUM

Additional Creeps can be added by creating another calibration block for the new name.

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

# Calibration

Before a newly built creep is flashed with the production firmware, its servo endpoints should be measured using:

```text
CreepyEyesCalibration.ino
```

The calibration sketch provides direct manual control of both servos from the Arduino Serial Monitor.

It does not use BLE and does not require `secrets.h`.

---

## Calibration Controls

Open the Arduino Serial Monitor at:

```text
115200 baud
```

The calibration sketch starts both servos at:

```text
90
```

Available commands:

```text
L = select LEFT servo
R = select RIGHT servo
+ = increase selected servo position by 1
- = decrease selected servo position by 1
P = print current servo positions
```

Example:

```text
L
+
+
+
P
```

selects the LEFT servo, increases its position three steps, then prints the current LEFT and RIGHT positions.

---

## Calibration Procedure

The goal is to determine four values for every physical creep:

```text
LEFT_OPEN
LEFT_CLOSED
RIGHT_OPEN
RIGHT_CLOSED
```

Recommended procedure:

1. Flash `CreepyEyesCalibration.ino`.
2. Open Serial Monitor at `115200`.
3. Select the LEFT servo with `L`.
4. Use `+` and `-` until the LEFT eye is fully open without mechanically forcing the linkage.
5. Record the LEFT OPEN value.
6. Move the LEFT eye to its desired fully closed position.
7. Record the LEFT CLOSED value.
8. Select the RIGHT servo with `R`.
9. Repeat the process to determine RIGHT OPEN and RIGHT CLOSED.
10. Use `P` to verify the current servo values as needed.
11. Record all four final values.
12. Add those values to the matching `CREEP_NAME` calibration block in `CreepyEyes.ino`.
13. Flash the production firmware and perform a full-power motion test.

Do not drive a servo farther once the mechanical linkage reaches its safe endpoint.

---

## Per-Creep Calibration

Each creep has unique servo endpoints.

The production firmware selects the correct calibration automatically using `CREEP_NAME`.

Example:

```cpp
if (name == "KUATO") {

    LEFT_OPEN    = 130;
    LEFT_CLOSED  = 67;

    RIGHT_OPEN   = 76;
    RIGHT_CLOSED = 115;
}
```

When adding a new creep:

1. mechanically build the glasses
2. run `CreepyEyesCalibration.ino`
3. determine:
   - LEFT OPEN
   - LEFT CLOSED
   - RIGHT OPEN
   - RIGHT CLOSED
4. add a calibration block for the new creep name to `CreepyEyes.ino`
5. set that same name in the local `secrets.h`
6. flash the production firmware
7. verify BLE and servo operation on battery power

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
```

### Default Behavior

```text
L = L:1.00
R = R:1.00
B = B:3.00:1.00
I = I:1.00:0.50:1.50
C = C:1.00:0.50:1.50:<default seed>
```

Where:

- `L` = one Left Wink
- `R` = one Right Wink
- `B` = repeating Blink
- `I` = Independent Creepy
- `C` = Coordinated Creepy
- `S` = Stop / Eyes Open

The firmware also accepts the simple single-letter commands and falls back to built-in defaults where applicable.

---

## Coordinated Creepy Mode

Coordinated Creepy mode uses a shared pseudo-random seed.

The iPhone app generates one seed and sends the same `C` command to every participating creep.

Example:

```text
C:1.00:0.50:1.50:123456789
```

All Creeps receiving that same seed generate the same sequence of:

- random action
- random speed
- next random action
- next random speed

This creates movement that appears random while remaining synchronized across the fleet.

The seed itself is not a user setting and does not need to be meaningful. It is simply used to ensure every creep follows the same pseudo-random sequence.

Typing `C` by itself uses the firmware's built-in fallback seed.

---

## Performance Mode

Performance mode is orchestrated by the iPhone app rather than hard-coded into the firmware.

The default sequence is:

```text
Left Wink
→ Right Wink
→ Blink
→ Independent Creepy
→ Coordinated Creepy
```

The first four actions run for the configured Performance duration before advancing.

Coordinated Creepy is the final resting state and continues until another command is sent.

`S` immediately stops the active behavior and opens both eyes.

---

## Local Secrets

The production firmware uses a local `secrets.h` file for values that should not be committed to source control.

The calibration sketch does not require this file.

A sample file is provided as:

```text
secrets.example.h
```

Copy it to:

```text
secrets.h
```

Then edit the local file.

Example:

```cpp
#pragma once

#define CREEP_NAME "KUATO"
#define FLEET_PASSCODE 123456
```

Change `CREEP_NAME` before flashing each physical creep.

Examples:

```cpp
#define CREEP_NAME "KUATO"
```

```cpp
#define CREEP_NAME "IGOR"
```

```cpp
#define CREEP_NAME "GOLLUM"
```

The fleet passcode should remain the same across Creeps that are intended to operate together.

---

## Important

`secrets.h` must not be committed.

The repository `.gitignore` should include:

```gitignore
secrets.h
```

Only:

```text
secrets.example.h
```

should be committed.

If a real passcode is ever committed accidentally, adding the file to `.gitignore` afterward does not remove it from Git history.

Rotate the exposed passcode before making the repository public.

---

## Production Flashing

Recommended production flash workflow:

1. calibrate the creep using `CreepyEyesCalibration.ino`
2. record all four servo endpoints
3. add or verify the creep's calibration block in `CreepyEyes.ino`
4. confirm the correct local `CREEP_NAME` in `secrets.h`
5. select `XIAO_ESP32C3`
6. compile
7. upload `CreepyEyes.ino`
8. open Serial Monitor at `115200`
9. verify the reported creep name and calibration
10. test BLE commands
11. perform a full-power servo test using the battery / 5V servo rail
12. complete final wire management and packaging

USB power alone is sufficient for the XIAO and BLE logic, but it does not provide the normal 5V servo rail used by the completed glasses.

A final motion test should therefore be performed using normal battery power before final assembly.

---

## Serial Testing

The production firmware accepts the same command parser from BLE and the Arduino Serial Monitor.

Example commands:

```text
L
R
B
I
S
```

Parameterized examples:

```text
L:1.00
R:1.00
B:3.00:1.00
I:1.00:0.50:1.50
C:1.00:0.50:1.50:123456789
S
```

---

## Files in This Directory

```text
firmware/
├── CreepyEyes.ino
├── CreepyEyesCalibration.ino
├── README.md
└── secrets.example.h
```

### `CreepyEyes.ino`

Shared production firmware for all Creeps.

### `CreepyEyesCalibration.ino`

Manual servo calibration utility used to determine each physical creep's OPEN and CLOSED servo endpoints.

### `secrets.example.h`

Safe template for the local production `secrets.h`.

The real `secrets.h` is intentionally excluded from source control.

---

## Design Philosophy

The firmware owns:

- servo positions
- calibration
- movement timing
- motion behavior
- safe stop behavior

The iPhone app owns:

- user settings
- target selection
- fleet control
- Performance sequencing
- Coordinated Creepy seed generation

The calibration sketch owns one job only:

- determining safe, repeatable servo endpoints for a physical creep

This keeps the BLE contract small, keeps raw servo positions out of the iPhone app, and gives each physical creep an explicit calibration step before production firmware is installed.