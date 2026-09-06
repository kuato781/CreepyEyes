import SwiftUI
import CoreBluetooth

struct ContentView: View {

    @StateObject private var bleManager = BLEManager()

    var body: some View {

        NavigationStack {

            ZStack {

                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 24) {

                        header

                        statusCard

                        if bleManager.isConnected {
                            connectedControls
                        } else {
                            scanView
                        }

                        brandingFooter
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(spacing: 8) {

            Image(systemName: "eyes")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.blue)

            Text("Creepy Eyes")
                .font(.system(size: 34, weight: .bold))

            Text("Wireless Creep Control")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status

    private var statusCard: some View {

        HStack(spacing: 12) {

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(bleManager.status)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var statusColor: Color {

        if bleManager.isConnected {
            return .green
        }

        if bleManager.bluetoothReady {
            return .blue
        }

        return .orange
    }

    // MARK: - Scan View

    private var scanView: some View {

        VStack(spacing: 18) {

            Button {
                bleManager.startScanning()
            } label: {
                Label(
                    "Scan for Creeps",
                    systemImage: "dot.radiowaves.left.and.right"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!bleManager.bluetoothReady)

            if bleManager.discoveredDevices.isEmpty {

                VStack(spacing: 12) {

                    Image(systemName: "binoculars")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)

                    Text("No Creeps Found")
                        .font(.headline)

                    Text(
                        "Make sure a creep is powered on and advertising."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding(.top, 36)

            } else {

                VStack(spacing: 14) {

                    ForEach(
                        bleManager.discoveredDevices,
                        id: \.identifier
                    ) { peripheral in

                        VStack(spacing: 12) {

                            HStack {

                                Image(systemName: "eyes")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                VStack(
                                    alignment: .leading,
                                    spacing: 3
                                ) {

                                    Text(
                                        bleManager.displayName(
                                            for: peripheral
                                        )
                                    )
                                    .font(.title3)
                                    .bold()

                                    Text("Available")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }

                                Spacer()
                            }

                            Button {
                                bleManager.connect(to: peripheral)
                            } label: {
                                Label(
                                    "Connect to \(bleManager.displayName(for: peripheral))",
                                    systemImage: "link"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    Color(
                                        .secondarySystemBackground
                                    )
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Connected Controls

    private var connectedControls: some View {

        VStack(spacing: 20) {

            connectedDeviceCard

            VStack(spacing: 14) {

                controlButton(
                    title: "Blink",
                    systemImage: "eye",
                    command: "B",
                    prominent: true
                )

                controlButton(
                    title: "Creepy Mode",
                    systemImage: "sparkles",
                    command: "C",
                    prominent: true
                )

                HStack(spacing: 12) {

                    controlButton(
                        title: "Left Wink",
                        systemImage: "arrow.left.circle",
                        command: "L"
                    )

                    controlButton(
                        title: "Right Wink",
                        systemImage: "arrow.right.circle",
                        command: "R"
                    )
                }

                controlButton(
                    title: "Stop / Eyes Open",
                    systemImage: "eye.fill",
                    command: "S"
                )
            }

            Divider()
                .padding(.vertical, 4)

            Button(role: .destructive) {

                bleManager.disconnect()

            } label: {

                Label(
                    "Disconnect",
                    systemImage: "xmark.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Connected Device Card

    private var connectedDeviceCard: some View {

        VStack(spacing: 10) {

            Image(systemName: "eyes")
                .font(.system(size: 38))
                .foregroundStyle(.blue)

            Text(
                bleManager.connectedDeviceName
                ?? "Connected Creep"
            )
            .font(.system(size: 30, weight: .bold))

            Label(
                "Connected",
                systemImage: "checkmark.circle.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Control Button Helper

    @ViewBuilder
    private func controlButton(
        title: String,
        systemImage: String,
        command: String,
        prominent: Bool = false
    ) -> some View {

        if prominent {

            Button {
                bleManager.sendCommand(command)
            } label: {
                Label(
                    title,
                    systemImage: systemImage
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)

        } else {

            Button {
                bleManager.sendCommand(command)
            } label: {
                Label(
                    title,
                    systemImage: systemImage
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Branding

    private var brandingFooter: some View {

        VStack(spacing: 8) {

            Divider()
                .padding(.top, 8)

            Image("ArroyoCooperativeLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .padding(.top, 6)

            Text(
                "Built for highly questionable purposes."
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}
