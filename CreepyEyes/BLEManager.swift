import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var bluetoothReady = false
    @Published var isScanning = false
    @Published var status = "Starting Bluetooth..."

    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var connectedDevices: [CBPeripheral] = []

    @Published var connectingDeviceIDs: Set<UUID> = []
    @Published var readyDeviceIDs: Set<UUID> = []

    // MARK: - CoreBluetooth

    private var centralManager: CBCentralManager!

    // Each creep gets its OWN command characteristic.
    private var commandCharacteristics: [UUID: CBCharacteristic] = [:]

    // Creeps waiting for Stop acknowledgement before disconnect.
    private var pendingDisconnectIDs: Set<UUID> = []

    // MARK: - Creepy Eyes BLE UUIDs

    static let serviceUUID =
        CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")

    static let characteristicUUID =
        CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

    // MARK: - Init

    override init() {

        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: nil
        )
    }

    // MARK: - Convenience State

    var isAnyConnected: Bool {
        !connectedDevices.isEmpty
    }

    var connectedCount: Int {
        connectedDevices.count
    }

    var readyCount: Int {
        readyDeviceIDs.count
    }

    var availableDiscoveredDevices: [CBPeripheral] {

        discoveredDevices.filter { peripheral in

            !connectedDevices.contains(
                where: {
                    $0.identifier == peripheral.identifier
                }
            )
            &&
            !connectingDeviceIDs.contains(
                peripheral.identifier
            )
        }
    }

    // MARK: - Scanning

    func startScanning() {

        guard centralManager.state == .poweredOn else {
            status = "Bluetooth is not ready"
            return
        }

        discoveredDevices.removeAll()

        isScanning = true
        status = "Scanning for Creeps..."

        centralManager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
    }

    func stopScanning() {

        centralManager.stopScan()

        isScanning = false

        if isAnyConnected {

            status = fleetReadyStatus()

        } else {

            status = "Scan stopped"
        }
    }

    // MARK: - Connection

    func connect(to peripheral: CBPeripheral) {

        guard !connectedDevices.contains(
            where: {
                $0.identifier == peripheral.identifier
            }
        ) else {

            status =
                "\(displayName(for: peripheral)) is already connected"

            return
        }

        guard !connectingDeviceIDs.contains(
            peripheral.identifier
        ) else {

            return
        }

        connectingDeviceIDs.insert(
            peripheral.identifier
        )

        status =
            "Connecting to \(displayName(for: peripheral))..."

        peripheral.delegate = self

        centralManager.connect(
            peripheral,
            options: nil
        )
    }

    // MARK: - Disconnect One

    func disconnect(_ peripheral: CBPeripheral) {

        guard connectedDevices.contains(
            where: {
                $0.identifier == peripheral.identifier
            }
        ) else {
            return
        }

        let id = peripheral.identifier

        guard
            peripheral.state == .connected,
            let characteristic =
                commandCharacteristics[id]
        else {

            status =
                "Disconnecting \(displayName(for: peripheral))..."

            centralManager.cancelPeripheralConnection(
                peripheral
            )

            return
        }

        guard
            let stopData =
                "S".data(using: .utf8)
        else {

            centralManager.cancelPeripheralConnection(
                peripheral
            )

            return
        }

        status =
            "Stopping \(displayName(for: peripheral))..."

        pendingDisconnectIDs.insert(id)

        peripheral.writeValue(
            stopData,
            for: characteristic,
            type: .withResponse
        )
    }

    // MARK: - Disconnect All

    func disconnectAll() {

        guard !connectedDevices.isEmpty else {
            return
        }

        status = "Stopping Creep Fleet..."

        for peripheral in connectedDevices {

            let id = peripheral.identifier

            guard
                peripheral.state == .connected,
                let characteristic =
                    commandCharacteristics[id],
                let stopData =
                    "S".data(using: .utf8)
            else {

                centralManager.cancelPeripheralConnection(
                    peripheral
                )

                continue
            }

            pendingDisconnectIDs.insert(id)

            peripheral.writeValue(
                stopData,
                for: characteristic,
                type: .withResponse
            )
        }
    }

    // MARK: - Commands

    /// Send to ONE creep.
    func sendCommand(
        _ command: String,
        to deviceID: UUID
    ) {

        guard
            let peripheral =
                connectedDevices.first(
                    where: {
                        $0.identifier == deviceID
                    }
                )
        else {

            status = "Creep is not connected"
            return
        }

        guard readyDeviceIDs.contains(deviceID) else {

            status =
                "\(displayName(for: peripheral)) is not ready"

            return
        }

        guard
            let characteristic =
                commandCharacteristics[deviceID]
        else {

            status =
                "\(displayName(for: peripheral)) has no command channel"

            return
        }

        guard
            let data =
                command.data(using: .utf8)
        else {

            status = "Could not encode command"
            return
        }

        peripheral.writeValue(
            data,
            for: characteristic,
            type: .withResponse
        )

        status =
            "Sent \(commandName(command)) to \(displayName(for: peripheral))"
    }

    /// Send to EVERY ready creep currently connected
    /// to this iPhone.
    func sendCommandToAll(
        _ command: String
    ) {

        let targets =
            connectedDevices.filter {

                readyDeviceIDs.contains(
                    $0.identifier
                )
                &&
                commandCharacteristics[
                    $0.identifier
                ] != nil
            }

        guard !targets.isEmpty else {

            status = "No Creeps ready"
            return
        }

        guard
            let data =
                command.data(using: .utf8)
        else {

            status = "Could not encode command"
            return
        }

        for peripheral in targets {

            guard
                let characteristic =
                    commandCharacteristics[
                        peripheral.identifier
                    ]
            else {
                continue
            }

            peripheral.writeValue(
                data,
                for: characteristic,
                type: .withResponse
            )
        }

        if targets.count == 1 {

            status =
                "Sent \(commandName(command)) to \(displayName(for: targets[0]))"

        } else {

            status =
                "Sent \(commandName(command)) to ALL \(targets.count) Creeps"
        }
    }

    // MARK: - Readiness

    func isReady(
        _ peripheral: CBPeripheral
    ) -> Bool {

        readyDeviceIDs.contains(
            peripheral.identifier
        )
    }

    func isConnecting(
        _ peripheral: CBPeripheral
    ) -> Bool {

        connectingDeviceIDs.contains(
            peripheral.identifier
        )
    }

    // MARK: - Helpers

    func displayName(
        for peripheral: CBPeripheral
    ) -> String {

        peripheral.name
        ?? "Unnamed Creep"
    }

    private func commandName(
        _ command: String
    ) -> String {

        switch command.uppercased() {

        case "B":
            return "Blink"

        case "C":
            return "Creepy Mode"

        case "L":
            return "Left Wink"

        case "R":
            return "Right Wink"

        case "S":
            return "Stop / Eyes Open"

        default:
            return command
        }
    }

    private func fleetReadyStatus() -> String {

        if connectedCount == 1 {

            if let creep = connectedDevices.first {

                if isReady(creep) {

                    return
                        "\(displayName(for: creep)) ready"

                } else {

                    return
                        "\(displayName(for: creep)) connected"
                }
            }
        }

        if connectedCount > 1 {

            return
                "\(readyCount) of \(connectedCount) Creeps ready"
        }

        return "Bluetooth ready"
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager:
    CBCentralManagerDelegate {

    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {

        switch central.state {

        case .poweredOn:

            bluetoothReady = true
            status = "Bluetooth ready"

        case .poweredOff:

            bluetoothReady = false
            isScanning = false
            status = "Bluetooth is off"

        case .unauthorized:

            bluetoothReady = false
            isScanning = false
            status = "Bluetooth permission denied"

        case .unsupported:

            bluetoothReady = false
            isScanning = false
            status = "Bluetooth unsupported"

        case .resetting:

            bluetoothReady = false
            isScanning = false
            status = "Bluetooth resetting"

        case .unknown:

            bluetoothReady = false
            isScanning = false
            status = "Bluetooth state unknown"

        @unknown default:

            bluetoothReady = false
            isScanning = false
            status = "Unknown Bluetooth state"
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {

        guard !discoveredDevices.contains(
            where: {
                $0.identifier ==
                peripheral.identifier
            }
        ) else {
            return
        }

        discoveredDevices.append(peripheral)

        let name =
            peripheral.name
            ??
            advertisementData[
                CBAdvertisementDataLocalNameKey
            ] as? String
            ??
            "Unnamed Creep"

        print(
            "FOUND CREEP: \(name)"
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {

        connectingDeviceIDs.remove(
            peripheral.identifier
        )

        if !connectedDevices.contains(
            where: {
                $0.identifier ==
                peripheral.identifier
            }
        ) {

            connectedDevices.append(
                peripheral
            )
        }

        peripheral.delegate = self

        status =
            "Connected to \(displayName(for: peripheral)) — finding controls..."

        peripheral.discoverServices(
            [Self.serviceUUID]
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {

        connectingDeviceIDs.remove(
            peripheral.identifier
        )

        commandCharacteristics.removeValue(
            forKey: peripheral.identifier
        )

        readyDeviceIDs.remove(
            peripheral.identifier
        )

        pendingDisconnectIDs.remove(
            peripheral.identifier
        )

        if let error {

            status =
                "Connection failed: \(error.localizedDescription)"

        } else {

            status =
                "Connection failed"
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {

        let id = peripheral.identifier

        connectingDeviceIDs.remove(id)
        readyDeviceIDs.remove(id)
        pendingDisconnectIDs.remove(id)

        commandCharacteristics.removeValue(
            forKey: id
        )

        connectedDevices.removeAll {
            $0.identifier == id
        }

        if let error {

            status =
                "\(displayName(for: peripheral)) disconnected: \(error.localizedDescription)"

        } else if connectedDevices.isEmpty {

            status = "Disconnected"

        } else {

            status = fleetReadyStatus()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager:
    CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {

        if let error {

            status =
                "Service discovery failed for \(displayName(for: peripheral)): \(error.localizedDescription)"

            return
        }

        guard
            let services =
                peripheral.services
        else {

            status =
                "No Creepy Eyes service found on \(displayName(for: peripheral))"

            return
        }

        for service in services {

            if service.uuid ==
                Self.serviceUUID {

                peripheral.discoverCharacteristics(
                    [Self.characteristicUUID],
                    for: service
                )
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {

        if let error {

            status =
                "Characteristic discovery failed for \(displayName(for: peripheral)): \(error.localizedDescription)"

            return
        }

        guard
            let characteristics =
                service.characteristics
        else {

            status =
                "No command characteristic found on \(displayName(for: peripheral))"

            return
        }

        for characteristic
            in characteristics {

            if characteristic.uuid ==
                Self.characteristicUUID {

                commandCharacteristics[
                    peripheral.identifier
                ] = characteristic

                readyDeviceIDs.insert(
                    peripheral.identifier
                )

                status = fleetReadyStatus()

                print(
                    "CREEP READY: \(displayName(for: peripheral))"
                )
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        let id =
            peripheral.identifier

        if let error {

            status =
                "Write failed to \(displayName(for: peripheral)): \(error.localizedDescription)"

            // If this write was part of a requested
            // disconnect, release the creep anyway.
            if pendingDisconnectIDs.contains(id) {

                pendingDisconnectIDs.remove(id)

                centralManager.cancelPeripheralConnection(
                    peripheral
                )
            }

            return
        }

        // Stop command acknowledged.
        // Now safely release this creep.
        if pendingDisconnectIDs.contains(id),
           characteristic.uuid ==
            Self.characteristicUUID {

            pendingDisconnectIDs.remove(id)

            status =
                "Disconnecting \(displayName(for: peripheral))..."

            centralManager.cancelPeripheralConnection(
                peripheral
            )
        }
    }
}
