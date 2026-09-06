import SwiftUI
import CoreBluetooth

struct ContentView: View {

    @StateObject private var bleManager = BLEManager()

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Text("Creepy Eyes")
                    .font(.largeTitle)
                    .bold()

                Text(bleManager.status)
                    .foregroundStyle(.secondary)

                if bleManager.isConnected {
                    connectedControls
                } else {
                    scanView
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Scan View

    private var scanView: some View {

        VStack(spacing: 20) {

            Button("Scan for Creeps") {
                bleManager.startScanning()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!bleManager.bluetoothReady)

            if bleManager.discoveredDevices.isEmpty {

                Text("No Creeps Found")
                    .foregroundStyle(.secondary)
                    .padding(.top, 60)

            } else {

                ForEach(
                    bleManager.discoveredDevices,
                    id: \.identifier
                ) { peripheral in

                    VStack(spacing: 12) {

                        Text(
                            bleManager.displayName(
                                for: peripheral
                            )
                        )
                        .font(.title2)
                        .bold()

                        Text(peripheral.identifier.uuidString)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            print(
                                "CONNECT BUTTON TAPPED: \(bleManager.displayName(for: peripheral))"
                            )

                            bleManager.connect(
                                to: peripheral
                            )

                        } label: {

                            Text(
                                "Connect to \(bleManager.displayName(for: peripheral))"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                        .fill(
                            Color.gray.opacity(0.12)
                        )
                    )
                }
            }
        }
    }

    // MARK: - Connected Controls

    private var connectedControls: some View {

        VStack(spacing: 18) {

            if let name =
                bleManager.connectedDeviceName {

                Text(name)
                    .font(.title)
                    .bold()
            }

            Button("Blink") {
                bleManager.sendCommand("B")
            }
            .buttonStyle(.borderedProminent)

            Button("Creepy Mode") {
                bleManager.sendCommand("C")
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 20) {

                Button("Left Wink") {
                    bleManager.sendCommand("L")
                }

                Button("Right Wink") {
                    bleManager.sendCommand("R")
                }
            }
            .buttonStyle(.bordered)

            Button("Stop / Eyes Open") {
                bleManager.sendCommand("S")
            }
            .buttonStyle(.bordered)

            Divider()

            Button("Disconnect") {
                bleManager.disconnect()
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ContentView()
}
