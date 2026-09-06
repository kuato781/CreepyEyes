import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {

    @Published var bluetoothReady = false
    @Published var status = "Starting Bluetooth..."
    @Published var discoveredDevices: [CBPeripheral] = []

    @Published var connectedDevice: CBPeripheral?
    @Published var connectedDeviceName: String?
    @Published var isConnected = false

    private var centralManager: CBCentralManager!
    private var commandCharacteristic: CBCharacteristic?

    static let serviceUUID =
        CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")

    static let characteristicUUID =
        CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

    override init() {
        super.init()

        centralManager = CBCentralManager(
            delegate: self,
            queue: nil
        )
    }

    // MARK: - Scanning

    func startScanning() {

        guard centralManager.state == .poweredOn else {
            status = "Bluetooth is not ready"
            return
        }

        discoveredDevices.removeAll()

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
        status = "Scan stopped"
    }

    // MARK: - Connection

    func connect(to peripheral: CBPeripheral) {

        stopScanning()

        status = "Connecting to \(displayName(for: peripheral))..."

        peripheral.delegate = self

        centralManager.connect(
            peripheral,
            options: nil
        )
    }

    func disconnect() {

        guard let peripheral = connectedDevice else {
            return
        }

        status = "Disconnecting..."

        centralManager.cancelPeripheralConnection(
            peripheral
        )
    }

    // MARK: - Commands

    func sendCommand(_ command: String) {

        guard let peripheral = connectedDevice,
              let characteristic = commandCharacteristic else {

            status = "Creep not ready"
            return
        }

        guard let data = command.data(using: .utf8) else {
            status = "Could not encode command"
            return
        }

        peripheral.writeValue(
            data,
            for: characteristic,
            type: .withResponse
        )

        status = "Sent \(command)"
    }

    // MARK: - Helpers

    func displayName(for peripheral: CBPeripheral) -> String {
        peripheral.name ?? "Unnamed Creep"
    }
}

// ==================================================
// CENTRAL MANAGER
// ==================================================

extension BLEManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(
        _ central: CBCentralManager
    ) {

        switch central.state {

        case .poweredOn:
            bluetoothReady = true
            status = "Bluetooth ready"

        case .poweredOff:
            bluetoothReady = false
            status = "Bluetooth is off"

        case .unauthorized:
            bluetoothReady = false
            status = "Bluetooth permission denied"

        case .unsupported:
            bluetoothReady = false
            status = "Bluetooth unsupported"

        case .resetting:
            bluetoothReady = false
            status = "Bluetooth resetting"

        case .unknown:
            bluetoothReady = false
            status = "Bluetooth state unknown"

        @unknown default:
            bluetoothReady = false
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
            where: { $0.identifier == peripheral.identifier }
        ) else {
            return
        }

        discoveredDevices.append(peripheral)

        let name =
            peripheral.name ??
            advertisementData[
                CBAdvertisementDataLocalNameKey
            ] as? String ??
            "Unnamed Creep"

        print("FOUND CREEP: \(name)")
    }

    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {

        connectedDevice = peripheral
        connectedDeviceName = displayName(for: peripheral)
        isConnected = true

        status = "Connected to \(displayName(for: peripheral))"

        peripheral.delegate = self

        peripheral.discoverServices(
            [Self.serviceUUID]
        )
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {

        isConnected = false
        connectedDevice = nil
        connectedDeviceName = nil
        commandCharacteristic = nil

        status = "Connection failed"
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {

        isConnected = false
        connectedDevice = nil
        connectedDeviceName = nil
        commandCharacteristic = nil

        status = "Disconnected"
    }
}

// ==================================================
// PERIPHERAL / SERVICE / CHARACTERISTIC DISCOVERY
// ==================================================

extension BLEManager: CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {

        if let error {
            status = "Service discovery failed: \(error.localizedDescription)"
            return
        }

        guard let services = peripheral.services else {
            status = "No Creepy Eyes service found"
            return
        }

        for service in services {

            if service.uuid == Self.serviceUUID {

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
            status = "Characteristic discovery failed: \(error.localizedDescription)"
            return
        }

        guard let characteristics = service.characteristics else {
            status = "No command characteristic found"
            return
        }

        for characteristic in characteristics {

            if characteristic.uuid == Self.characteristicUUID {

                commandCharacteristic = characteristic

                status =
                    "\(displayName(for: peripheral)) ready"
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {

        if let error {
            status = "Write failed: \(error.localizedDescription)"
        }
    }
}
