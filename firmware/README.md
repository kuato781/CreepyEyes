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

Future Creeps can be added by adding a new calibration block for that name.

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

## Per-Creep Calibration

Each creep has unique servo endpoints.

The firmware selects the correct calibration automatically using `CREEP_NAME`.

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

1. mechanically build and calibrate the glasses
2. record:
   - LEFT OPEN
   - LEFT CLOSED
   - RIGHT OPEN
   - RIGHT CLOSED
3. add a calibration block for the new creep name
4. set that same name in the local `secrets.h`
5. flash the shared production firmware

---

## Local Secrets

The firmware uses a local `secrets.h` file for values that should not be committed to source control.

The real `secrets.h` must remain local.

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

Only `secrets.example.h` should be committed.

If a real passcode is ever committed accidentally, adding the file to `.gitignore` afterward does not remove it from Git history.

Rotate the exposed passcode before making the repository public.

---

## Flashing

Recommended flash workflow:

1. open the shared production `.ino`
2. confirm the correct local `CREEP_NAME` in `secrets.h`
3. select `XIAO_ESP32C3`
4. compile
5. upload
6. open Serial Monitor at `115200`
7. verify the reported creep name and calibration
8. test commands
9. move to the next creep

Example Serial Monitor commands:

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

## Current Firmware File

The current production firmware is:

```text
creepy_eyes_v2.ino
```

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

This keeps the BLE contract small and prevents the app from directly controlling raw servo positions.