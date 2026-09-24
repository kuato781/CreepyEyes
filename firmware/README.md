# CreepyEyes Firmware

Firmware for the servo-driven CreepyEyes glasses.

This directory contains:

- shared production firmware for the Creep Fleet
- a calibration sketch used when building or servicing an individual creep

```text
firmware/
├── CreepyEyes/
│   ├── CreepyEyes.ino
│   └── secrets.example.h
├── CreepyEyesCalibration/
│   └── CreepyEyesCalibration.ino
└── README.md
```

## Hardware mapping

Current controller: **Seeed Studio XIAO ESP32-C3**.

**LEFT and RIGHT are defined from the wearer's perspective.**

```text
D4 = wearer's LEFT servo
D5 = wearer's RIGHT servo
```

The servos are powered from the separate boosted ~5 V rail, not the XIAO 3V3 pin. Controller and servo rail share ground.

For full hardware wiring see [../hardware/WIRING.md](../hardware/WIRING.md).

## Shared production firmware

The same `CreepyEyes.ino` is used across the fleet.

Per-creep differences are selected using `CREEP_NAME` and calibration blocks inside the firmware.

Named Creeps currently represented in the firmware:

- KUATO
- IGOR
- GOLLUM
- FESTER
- LURCH

## Arduino environment

Current development environment:

- Arduino IDE
- `esp32 by Espressif Systems`
- board: `XIAO_ESP32C3`
- `ESP32Servo`
- Serial Monitor: `115200`

## Calibration

Before flashing production firmware onto a newly built creep, measure its servo endpoints with:

```text
firmware/CreepyEyesCalibration/CreepyEyesCalibration.ino
```

The sketch starts both servos at 90 and accepts:

```text
L = select LEFT servo
R = select RIGHT servo
+ = increase selected position by 1
- = decrease selected position by 1
P = print current positions
```

The four values required for each physical creep are:

```text
LEFT_OPEN
LEFT_CLOSED
RIGHT_OPEN
RIGHT_CLOSED
```

Recommended process:

1. mechanically assemble and inspect the glasses
2. flash the calibration sketch
3. open Serial Monitor at 115200
4. select LEFT and determine safe OPEN/CLOSED endpoints
5. select RIGHT and determine safe OPEN/CLOSED endpoints
6. record all four values
7. add/update the creep's calibration block in `CreepyEyes.ino`
8. set the matching local `CREEP_NAME`
9. flash production firmware
10. test BLE and full battery-powered motion

Do not keep driving a servo after the linkage reaches its safe mechanical endpoint.

## BLE protocol

All Creeps share the same BLE service and characteristic UUIDs and advertise using their configured `CREEP_NAME`.

```text
L:<speed>
R:<speed>
B:<transition interval>:<speed>
I:<transition interval>:<minimum speed>:<maximum speed>
C:<transition interval>:<minimum speed>:<maximum speed>:<seed>
S
```

Defaults:

```text
L = L:1.00
R = R:1.00
B = B:3.00:1.00
I = I:1.00:0.50:1.50
C = C:1.00:0.50:1.50:<default seed>
```

`L` and `R` are one-shot winks. `B` repeats blink behavior. `I` runs Independent Creepy. `C` uses a deterministic shared pseudo-random seed for Coordinated Creepy. `S` stops the active mode and opens the eyes.

The production firmware accepts the same parser from BLE and the Serial Monitor, so commands can be tested from either path.

## Performance mode

Performance is implemented in the iPhone app, not as a firmware opcode.

The app sequences Left Wink, Right Wink, Blink, Independent Creepy, then Coordinated Creepy. Firmware simply executes the semantic commands it receives.

## Local secrets

Production firmware uses a local `secrets.h` containing the creep identity and fleet BLE passcode.

Start from:

```text
firmware/CreepyEyes/secrets.example.h
```

Example local file:

```cpp
#pragma once
#define CREEP_NAME "KUATO"
#define FLEET_PASSCODE 123456
```

`secrets.h` must not be committed. The real passcode should remain local and should be rotated if ever exposed in repository history.

## Production flashing workflow

1. calibrate with `CreepyEyesCalibration.ino`
2. record endpoints
3. update/verify the creep calibration block in `CreepyEyes.ino`
4. set the correct local `CREEP_NAME`
5. select `XIAO_ESP32C3`
6. compile and upload production firmware
7. open Serial Monitor at 115200
8. confirm creep identity and calibration
9. test BLE commands
10. perform a full-power test with the normal battery/boost servo rail
11. finish permanent wiring/packaging only after the test passes

USB can power the XIAO/BLE logic, but it does not represent the normal boosted servo-power path. Final motion testing therefore needs the glasses' battery power switched on.
