# CreepyEyes

Native iPhone controller for servo-driven **Creepy Eyes** glasses using Bluetooth Low Energy (BLE).

Built by Arroyo Cooperative for highly questionable purposes. 👀

## What It Does

The app discovers nearby Creepy Eyes devices advertising the shared BLE service, connects securely to a selected pair, and sends simple control commands to the glasses.

Current working controls:

- **Blink**
- **Creepy Mode**
- **Left Wink**
- **Right Wink**
- **Stop / Eyes Open**
- **Disconnect**

Disconnect first sends a Stop command so the glasses return to the fully open state before the BLE connection is released.

## Current Status

Single-creep control is fully functional.

Tested with the first Creepy Eyes unit:

- **KUATO**
- XIAO ESP32-C3 controller
- secure BLE pairing
- shared fleet passcode
- native iPhone app
- real-time servo control
- authenticated BLE command characteristic

The app currently:

1. Scans only for devices advertising the Creepy Eyes BLE service UUID.
2. Displays available devices by their advertised character name.
3. Connects to one creep at a time.
4. Discovers the command characteristic.
5. Sends UTF-8 command strings over BLE.
6. Displays readable status messages in the UI.
7. Safely stops the creep before disconnecting.

## Creepy Fleet

Planned device names:

- `KUATO`
- `IGOR`
- `GOLLUM`
- `FESTER`

Each pair of glasses uses:

- the same BLE service UUID
- the same BLE characteristic UUID
- the same command protocol
- its own advertised device name
- its own per-pair servo calibration values

## BLE Protocol

### Service UUID

```text
4fafc201-1fb5-459e-8fcc-c5c9c331914b
