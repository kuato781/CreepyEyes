# CreepyEyes

Native iPhone BLE control system for servo-driven **Creepy Eyes** glasses.

Built by Arroyo Cooperative for highly questionable purposes. 👀

CreepyEyes combines:

- a native SwiftUI iPhone app
- BLE-connected XIAO ESP32-C3 controllers
- servo-driven eye mechanisms
- per-creep calibration
- multi-device fleet control
- synchronized random movement
- configurable motion behavior
- app-orchestrated Performance mode

---

## Current Status

CreepyEyes V2 is currently functional across three physical Creeps:

- `KUATO`
- `IGOR`
- `GOLLUM`

Each pair of glasses has:

- its own advertised BLE name
- its own servo calibration
- the same shared BLE service
- the same BLE characteristic
- the same command protocol
- the same shared production firmware

The iPhone app can connect to one or multiple Creeps at the same time.

Current fleet behavior has been tested successfully across all three devices.

---

## What the App Does

The iPhone app:

- scans for nearby CreepyEyes devices
- connects securely over BLE
- displays each creep by its advertised name
- controls a single creep or the connected fleet
- stores user-adjustable motion settings locally
- sends parameterized behavior commands to the firmware
- orchestrates Performance mode
- generates shared seeds for synchronized Coordinated Creepy behavior
- safely stops Creeps before disconnecting

The app currently supports:

- **Blink**
- **Left Wink**
- **Right Wink**
- **Independent Creepy**
- **Coordinated Creepy**
- **Performance**
- **Stop / Eyes Open**
- **Disconnect**
- **Disconnect All Creeps**

---

## Creep Fleet

Current physical Creeps:

- `KUATO`
- `IGOR`
- `GOLLUM`

Each creep uses:

- the same production firmware
- the same BLE UUIDs
- the same command protocol
- its own `CREEP_NAME`
- its own servo calibration values

The firmware selects the correct calibration automatically from the configured creep name.

---

## Single-Creep Control

With one creep connected, the app behaves as a normal individual controller.

Available behaviors include:

- Blink
- Independent Creepy
- Left Wink
- Right Wink
- Stop / Eyes Open

Manual Left Wink and Right Wink commands perform one wink.

---

## Fleet Control

When multiple Creeps are connected, the app displays:

- `ALL`
- each individually connected creep

Commands can be sent to an individual creep or to the fleet.

Fleet-only behaviors currently include:

- **Coordinated Creepy**
- **Performance**

These become available when multiple Creeps are connected and `ALL` is selected.

---

## Independent Creepy

Independent Creepy causes each creep to generate its own random movement sequence.

Each device independently chooses:

- movement type
- movement speed
- subsequent random actions

This creates intentionally uncoordinated creepy motion across the fleet.

---

## Coordinated Creepy

Coordinated Creepy causes every participating creep to perform the same pseudo-random movement sequence.

The iPhone app:

1. generates a random seed
2. sends the same seed to every creep
3. sends the same motion parameters to every creep

Because the firmware uses a deterministic pseudo-random sequence, Creeps receiving the same seed generate the same:

- movement
- speed
- next movement
- next speed

The result appears random while remaining synchronized across the fleet.

---

## Performance Mode

Performance mode is orchestrated by the iPhone app.

The default sequence is:

```text
Left Wink
→ Right Wink
→ Blink
→ Independent Creepy
→ Coordinated Creepy
```

The first four actions run for a configurable amount of time.

The default Performance action duration is:

```text
10 seconds
```

The final Coordinated Creepy phase runs indefinitely until another command is sent.

`Stop / Eyes Open` immediately interrupts Performance at any point.

---

## Settings

The app includes a local Settings screen.

Settings are stored on the iPhone and do not require a database or external service.

Current adjustable settings include:

### Wink

- Wink Interval
- Wink Speed

Wink Interval applies when Performance repeatedly triggers wink behavior.

Manual Left Wink and Right Wink commands remain single actions.

### Blink

- Blink Interval
- Blink Speed

### Creepy

- Transition Interval
- Minimum Speed
- Maximum Speed

### Performance

- Action Duration

Each setting includes an individual **Reset** control.

The Settings screen also includes:

- **Restore All Defaults**

---

## Current Factory Defaults

```text
Wink Interval               3.0 sec
Wink Speed                  1.0x

Blink Interval              3.0 sec
Blink Speed                 1.0x

Creepy Transition Interval  1.0 sec
Creepy Minimum Speed        0.5x
Creepy Maximum Speed        1.5x

Performance Action Duration 10 sec
```

---

## BLE Protocol

### Service UUID

```text
4fafc201-1fb5-459e-8fcc-c5c9c331914b
```

### Characteristic UUID

```text
beb5483e-36e1-4688-b7f5-ea07361b26a8
```

All Creeps use the same BLE service and characteristic UUIDs.

Each creep advertises under its own configured name.

---

## Current BLE Commands

```text
L:<speed>
R:<speed>
B:<transition interval>:<speed>
I:<transition interval>:<minimum speed>:<maximum speed>
C:<transition interval>:<minimum speed>:<maximum speed>:<seed>
S
```

Default equivalents:

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

For Coordinated Creepy, the iPhone app normally supplies a shared random seed so all participating Creeps follow the same pseudo-random sequence.

---

## Safe Stop / Disconnect

`S` is the universal stop command.

It:

- cancels the active behavior
- stops Performance
- returns the eyes to the open position

Disconnect operations send Stop before releasing the BLE connection.

---

## Firmware

The production firmware lives in:

```text
firmware/
```

The firmware runs on the Seeed Studio XIAO ESP32-C3 and owns:

- servo control
- movement interpolation
- blink / wink behavior
- Independent Creepy behavior
- Coordinated Creepy behavior
- per-creep calibration
- BLE security
- BLE command parsing
- safe stop behavior

See:

```text
firmware/README.md
```

for firmware-specific setup, flashing, command, and secrets documentation.

---

## Secrets

Production firmware uses a local:

```text
secrets.h
```

for values that should not be committed to source control.

A safe template is provided as:

```text
secrets.example.h
```

Typical local configuration:

```cpp
#pragma once

#define CREEP_NAME "KUATO"
#define FLEET_PASSCODE 123456
```

The real fleet passcode must remain local.

`secrets.h` is intentionally excluded through `.gitignore`.

---

## Current Repository Structure

```text
CreepyEyes/
├── .gitignore
├── README.md
├── LICENSE
├── DISCLAIMER.md
│
├── firmware/
│   ├── README.md
│   ├── creepy_eyes_v2.ino
│   └── secrets.example.h
│
└── CreepyEyes/
    ├── BLEManager.swift
    ├── CreepyEyes.xcodeproj
    │
    └── CreepyEyes/
        ├── ContentView.swift
        ├── CreepyEyesApp.swift
        └── Assets.xcassets/
```

---

## iPhone App Architecture

The iPhone application is written in Swift / SwiftUI.

### `BLEManager.swift`

Owns BLE state and communication:

- scanning
- connection management
- characteristic discovery
- per-device command channels
- command transmission
- safe disconnect behavior
- multi-creep connection state

### `ContentView.swift`

Owns application UI and behavior orchestration:

- target selection
- command controls
- Settings
- local persisted motion values
- Performance sequencing
- Coordinated Creepy seed generation

The app sends semantic behavior commands rather than raw servo positions.

---

## Hardware Orientation Convention

Servo side naming is always defined while looking **at the glasses from the front**.

```text
D4 = LEFT
D5 = RIGHT
```

This convention is used consistently for firmware calibration and documentation.

---

## Development Environment

Current firmware environment:

- Arduino IDE
- Seeed Studio XIAO ESP32-C3
- `esp32` board package by Espressif Systems
- `ESP32Servo`
- Serial Monitor at `115200`

Current app environment:

- Xcode
- Swift
- SwiftUI
- CoreBluetooth
- native iPhone deployment

---

## Design Philosophy

The system intentionally separates responsibilities.

### Firmware owns:

- raw servo positions
- calibration
- movement execution
- motion timing
- safe mechanical behavior

### iPhone app owns:

- user settings
- target selection
- fleet orchestration
- Performance sequencing
- Coordinated Creepy seed generation

This keeps the BLE interface small and avoids exposing raw servo control to the application layer.

---

## License

See:

```text
LICENSE
```

for permitted use.

---

## Disclaimer

CreepyEyes is a hobbyist wearable electronics project involving:

- LiPo batteries
- moving mechanical components
- servo motors
- custom wiring
- BLE-connected electronics

See:

```text
DISCLAIMER.md
```

for safety and usage information.