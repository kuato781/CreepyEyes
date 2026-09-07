import SwiftUI
import CoreBluetooth

struct ContentView: View {

    @StateObject private var bleManager =
        BLEManager()

    // nil = ALL connected Creeps.
    // UUID = one specific Creep.
    @State private var selectedTargetID:
        UUID? = nil

    var body: some View {

        NavigationStack {

            ZStack {

                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {

                    VStack(spacing: 24) {

                        header

                        statusCard

                        if bleManager.isAnyConnected {

                            connectedFleetView

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
                .font(
                    .system(
                        size: 44,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.blue)

            Text("Creepy Eyes")
                .font(
                    .system(
                        size: 34,
                        weight: .bold
                    )
                )

            Text(
                "Wireless Creep Control"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Status

    private var statusCard: some View {

        HStack(spacing: 12) {

            Circle()
                .fill(statusColor)
                .frame(
                    width: 10,
                    height: 10
                )

            Text(bleManager.status)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 14
            )
            .fill(
                Color(
                    .secondarySystemBackground
                )
            )
        )
    }

    private var statusColor: Color {

        if bleManager.isAnyConnected {
            return .green
        }

        if bleManager.bluetoothReady {
            return .blue
        }

        return .orange
    }

    // MARK: - Initial Scan View

    private var scanView: some View {

        VStack(spacing: 18) {

            scanButton(
                title: bleManager.isScanning
                    ? "Scanning for Creeps..."
                    : "Scan for Creeps"
            )

            if bleManager.discoveredDevices.isEmpty {

                VStack(spacing: 12) {

                    Image(
                        systemName: "binoculars"
                    )
                    .font(
                        .system(size: 34)
                    )
                    .foregroundStyle(
                        .secondary
                    )

                    Text("No Creeps Found")
                        .font(.headline)

                    Text(
                        "Make sure a creep is powered on and advertising."
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                }
                .padding(.top, 36)

            } else {

                VStack(spacing: 14) {

                    ForEach(
                        bleManager
                            .availableDiscoveredDevices,
                        id: \.identifier
                    ) { peripheral in

                        availableCreepCard(
                            peripheral
                        )
                    }
                }
            }
        }
    }

    // MARK: - Connected Fleet View

    private var connectedFleetView:
        some View {

        VStack(spacing: 20) {

            fleetSummaryCard

            connectedCreepsSection

            if bleManager.connectedCount > 1 {

                targetSelector
            }

            controlsSection

            addMoreCreepsSection

            Divider()
                .padding(.vertical, 4)

            if bleManager.connectedCount > 1 {

                Button(role: .destructive) {

                    selectedTargetID = nil
                    bleManager.disconnectAll()

                } label: {

                    Label(
                        "Disconnect All Creeps",
                        systemImage:
                            "xmark.circle.fill"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.bordered)

            } else if
                let onlyCreep =
                    bleManager
                        .connectedDevices
                        .first {

                Button(role: .destructive) {

                    selectedTargetID = nil

                    bleManager.disconnect(
                        onlyCreep
                    )

                } label: {

                    Label(
                        "Disconnect",
                        systemImage:
                            "xmark.circle"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Fleet Summary

    private var fleetSummaryCard:
        some View {

        VStack(spacing: 10) {

            Image(systemName: "eyes")
                .font(
                    .system(size: 38)
                )
                .foregroundStyle(.blue)

            if bleManager.connectedCount == 1 {

                Text(
                    bleManager.displayName(
                        for:
                            bleManager
                                .connectedDevices[0]
                    )
                )
                .font(
                    .system(
                        size: 30,
                        weight: .bold
                    )
                )

                Label(
                    "Connected",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.green)

            } else {

                Text("Creep Fleet")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold
                        )
                    )

                Label(
                    "\(bleManager.connectedCount) Creeps Connected",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(
                cornerRadius: 20
            )
            .fill(
                Color(
                    .secondarySystemBackground
                )
            )
        )
    }

    // MARK: - Connected Creeps

    private var connectedCreepsSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            if bleManager.connectedCount > 1 {

                Text("Connected Creeps")
                    .font(.headline)
            }

            ForEach(
                bleManager.connectedDevices,
                id: \.identifier
            ) { peripheral in

                HStack(spacing: 12) {

                    Image(
                        systemName: "eyes"
                    )
                    .font(.title3)
                    .foregroundStyle(.blue)

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(
                            bleManager
                                .displayName(
                                    for: peripheral
                                )
                        )
                        .font(.headline)

                        if bleManager.isReady(
                            peripheral
                        ) {

                            Text("Ready")
                                .font(.caption)
                                .foregroundStyle(
                                    .green
                                )

                        } else {

                            Text(
                                "Connecting..."
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }

                    Spacer()

                    if bleManager.connectedCount > 1 {

                        Button(
                            role: .destructive
                        ) {

                            if
                                selectedTargetID ==
                                    peripheral
                                        .identifier {

                                selectedTargetID =
                                    nil
                            }

                            bleManager.disconnect(
                                peripheral
                            )

                        } label: {

                            Image(
                                systemName:
                                    "xmark.circle"
                            )
                        }
                        .buttonStyle(
                            .borderless
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                    .fill(
                        Color(
                            .secondarySystemBackground
                        )
                    )
                )
            }
        }
    }

    // MARK: - Target Selector

    private var targetSelector:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            Text("Control Target")
                .font(.headline)

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                HStack(spacing: 10) {

                    targetButton(
                        title: "ALL",
                        targetID: nil
                    )

                    ForEach(
                        bleManager
                            .connectedDevices,
                        id: \.identifier
                    ) { peripheral in

                        targetButton(
                            title:
                                bleManager
                                    .displayName(
                                        for:
                                            peripheral
                                    ),
                            targetID:
                                peripheral
                                    .identifier
                        )
                    }
                }
            }
        }
    }

    // MARK: - Control Target Button

    @ViewBuilder
    private func targetButton(
        title: String,
        targetID: UUID?
    ) -> some View {

        let isSelected =
            selectedTargetID ==
            targetID

        if isSelected {

            Button {

                selectedTargetID =
                    targetID

            } label: {

                Text(title)
                    .font(.headline)
            }
            .buttonStyle(
                .borderedProminent
            )

        } else {

            Button {

                selectedTargetID =
                    targetID

            } label: {

                Text(title)
                    .font(.headline)
            }
            .buttonStyle(
                .bordered
            )
        }
    }

    // MARK: - Controls

    private var controlsSection:
        some View {

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
                    systemImage:
                        "arrow.left.circle",
                    command: "L"
                )

                controlButton(
                    title: "Right Wink",
                    systemImage:
                        "arrow.right.circle",
                    command: "R"
                )
            }

            controlButton(
                title:
                    "Stop / Eyes Open",
                systemImage: "eye.fill",
                command: "S"
            )
        }
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

                sendCommand(
                    command
                )

            } label: {

                Label(
                    title,
                    systemImage:
                        systemImage
                )
                .font(.headline)
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .vertical,
                    5
                )
            }
            .buttonStyle(
                .borderedProminent
            )

        } else {

            Button {

                sendCommand(
                    command
                )

            } label: {

                Label(
                    title,
                    systemImage:
                        systemImage
                )
                .font(.headline)
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .vertical,
                    5
                )
            }
            .buttonStyle(
                .bordered
            )
        }
    }

    private func sendCommand(
        _ command: String
    ) {

        // One connected creep:
        // naturally behave like the original app.
        if bleManager.connectedCount == 1 {

            if let creep =
                bleManager
                    .connectedDevices
                    .first {

                bleManager.sendCommand(
                    command,
                    to:
                        creep.identifier
                )
            }

            return
        }

        // Multiple connected creeps:
        // nil means ALL.
        if let targetID =
            selectedTargetID {

            bleManager.sendCommand(
                command,
                to: targetID
            )

        } else {

            bleManager
                .sendCommandToAll(
                    command
                )
        }
    }

    // MARK: - Add More Creeps

    private var addMoreCreepsSection:
        some View {

        VStack(spacing: 14) {

            Divider()
                .padding(.top, 4)

            Text("Add Creeps")
                .font(.headline)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            scanButton(
                title:
                    bleManager.isScanning
                    ? "Scanning..."
                    : "Scan for More Creeps"
            )

            if !bleManager
                .availableDiscoveredDevices
                .isEmpty {

                VStack(spacing: 12) {

                    ForEach(
                        bleManager
                            .availableDiscoveredDevices,
                        id: \.identifier
                    ) { peripheral in

                        availableCreepCard(
                            peripheral
                        )
                    }
                }
            }
        }
    }

    // MARK: - Available Creep Card

    private func availableCreepCard(
        _ peripheral: CBPeripheral
    ) -> some View {

        VStack(spacing: 12) {

            HStack {

                Image(
                    systemName: "eyes"
                )
                .font(.title2)
                .foregroundStyle(.blue)

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        bleManager
                            .displayName(
                                for: peripheral
                            )
                    )
                    .font(.title3)
                    .bold()

                    if bleManager
                        .isConnecting(
                            peripheral
                        ) {

                        Text("Connecting...")
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )

                    } else {

                        Text("Available")
                            .font(.caption)
                            .foregroundStyle(
                                .green
                            )
                    }
                }

                Spacer()
            }

            Button {

                bleManager.connect(
                    to: peripheral
                )

            } label: {

                Label(
                    bleManager
                        .isConnecting(
                            peripheral
                        )
                    ? "Connecting..."
                    : "Connect to \(bleManager.displayName(for: peripheral))",
                    systemImage: "link"
                )
                .frame(
                    maxWidth: .infinity
                )
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                bleManager.isConnecting(
                    peripheral
                )
            )
        }
        .padding()
        .background(
            RoundedRectangle(
                cornerRadius: 18
            )
            .fill(
                Color(
                    .secondarySystemBackground
                )
            )
        )
    }

    // MARK: - Scan Button

    private func scanButton(
        title: String
    ) -> some View {

        Button {

            bleManager.startScanning()

        } label: {

            Label(
                title,
                systemImage:
                    "dot.radiowaves.left.and.right"
            )
            .font(.headline)
            .frame(
                maxWidth: .infinity
            )
            .padding(
                .vertical,
                6
            )
        }
        .buttonStyle(
            .borderedProminent
        )
        .disabled(
            !bleManager.bluetoothReady
        )
    }

    // MARK: - Branding

    private var brandingFooter:
        some View {

        VStack(spacing: 8) {

            Divider()
                .padding(.top, 8)

            Image(
                "ArroyoCooperativeLogo"
            )
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
