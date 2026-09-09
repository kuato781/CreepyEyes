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