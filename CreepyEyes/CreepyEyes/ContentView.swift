import SwiftUI
import CoreBluetooth
import Foundation

// MARK: - Factory Defaults

enum CreepDefaults {

    static let winkInterval = 3.0
    static let winkSpeed = 1.0

    static let blinkInterval = 3.0
    static let blinkSpeed = 1.0

    static let creepyTransitionInterval = 1.0
    static let creepyMinSpeed = 0.5
    static let creepyMaxSpeed = 1.5

    static let performanceActionDuration = 10.0
}

// MARK: - UserDefaults Keys

enum CreepSettingKeys {

    static let winkInterval =
        "creep.winkInterval"

    static let winkSpeed =
        "creep.winkSpeed"

    static let blinkInterval =
        "creep.blinkInterval"

    static let blinkSpeed =
        "creep.blinkSpeed"

    static let creepyTransitionInterval =
        "creep.creepyTransitionInterval"

    static let creepyMinSpeed =
        "creep.creepyMinSpeed"

    static let creepyMaxSpeed =
        "creep.creepyMaxSpeed"

    static let performanceActionDuration =
        "creep.performanceActionDuration"
}

// MARK: - Main View

struct ContentView: View {

    @StateObject private var bleManager =
        BLEManager()

    // nil = ALL connected Creeps.
    // UUID = one specific Creep.
    @State private var selectedTargetID:
        UUID? = nil

    // Performance is orchestrated by the
    // iPhone rather than hard-coded into
    // each individual Creep.
    @State private var performanceTask:
        Task<Void, Never>? = nil

    @State private var performanceRunning =
        false

    // MARK: Settings

    @AppStorage(
        CreepSettingKeys.winkInterval
    )
    private var winkInterval =
        CreepDefaults.winkInterval

    @AppStorage(
        CreepSettingKeys.winkSpeed
    )
    private var winkSpeed =
        CreepDefaults.winkSpeed

    @AppStorage(
        CreepSettingKeys.blinkInterval
    )
    private var blinkInterval =
        CreepDefaults.blinkInterval

    @AppStorage(
        CreepSettingKeys.blinkSpeed
    )
    private var blinkSpeed =
        CreepDefaults.blinkSpeed

    @AppStorage(
        CreepSettingKeys.creepyTransitionInterval
    )
    private var creepyTransitionInterval =
        CreepDefaults.creepyTransitionInterval

    @AppStorage(
        CreepSettingKeys.creepyMinSpeed
    )
    private var creepyMinSpeed =
        CreepDefaults.creepyMinSpeed

    @AppStorage(
        CreepSettingKeys.creepyMaxSpeed
    )
    private var creepyMaxSpeed =
        CreepDefaults.creepyMaxSpeed

    @AppStorage(
        CreepSettingKeys.performanceActionDuration
    )
    private var performanceActionDuration =
        CreepDefaults.performanceActionDuration

    // MARK: Body

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
            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    NavigationLink {

                        CreepSettingsView()

                    } label: {

                        Image(
                            systemName: "gearshape"
                        )
                    }
                    .accessibilityLabel(
                        "Settings"
                    )
                }
            }
        }
        .onChange(
            of: selectedTargetID
        ) { _, _ in

            // Changing targets in the middle
            // of Performance could leave some
            // Creeps running an old mode.
            //
            // Kill the show cleanly instead.
            if performanceRunning {

                stopPerformance(
                    sendStop: true
                )
            }
        }
        .onChange(
            of: bleManager.connectedCount
        ) { _, newCount in

            // Performance requires a fleet.
            if performanceRunning &&
                newCount < 2 {

                stopPerformance(
                    sendStop: true
                )
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
                title:
                    bleManager.isScanning
                    ? "Scanning for Creeps..."
                    : "Scan for Creeps"
            )

            if bleManager
                .discoveredDevices
                .isEmpty {

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

            Text("Commands")
                .font(.headline)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

            controlsSection

            addMoreCreepsSection

            Divider()
                .padding(.vertical, 4)

            if bleManager.connectedCount > 1 {

                Button(
                    role: .destructive
                ) {

                    stopPerformance(
                        sendStop: false
                    )

                    selectedTargetID = nil

                    bleManager
                        .disconnectAll()

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

                Button(
                    role: .destructive
                ) {

                    stopPerformance(
                        sendStop: false
                    )

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

            if bleManager.connectedCount == 1,
               let creep =
                bleManager
                    .connectedDevices
                    .first {

                Text(
                    bleManager
                        .displayName(
                            for: creep
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

                            if performanceRunning {

                                stopPerformance(
                                    sendStop: true
                                )
                            }

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

    // MARK: - Target Button

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

    private var fleetOnlyCommandsEnabled:
        Bool {

        // Current V2 selection model is
        // ONE creep or ALL.
        //
        // Therefore C and P are only valid
        // when ALL is selected and at least
        // two Creeps are connected.

        bleManager.connectedCount > 1
        &&
        selectedTargetID == nil
    }

    private var controlsSection:
        some View {

        VStack(spacing: 14) {

            controlButton(
                title: "Blink",
                systemImage: "eye",
                prominent: true
            ) {

                handleBehaviorCommand(
                    blinkCommand
                )
            }

            controlButton(
                title:
                    "Independent Creepy",
                systemImage: "sparkles",
                prominent: true
            ) {

                handleBehaviorCommand(
                    independentCreepyCommand
                )
            }

            controlButton(
                title:
                    "Coordinated Creepy",
                systemImage: "eyes",
                prominent: true,
                disabled:
                    !fleetOnlyCommandsEnabled
            ) {

                startCoordinatedCreepy()
            }

            controlButton(
                title:
                    performanceRunning
                    ? "Performance Running"
                    : "Performance",
                systemImage:
                    "play.circle.fill",
                prominent: true,
                disabled:
                    !fleetOnlyCommandsEnabled
                    ||
                    performanceRunning
            ) {

                startPerformance()
            }

            HStack(spacing: 12) {

                controlButton(
                    title: "Left Wink",
                    systemImage:
                        "arrow.left.circle"
                ) {

                    handleBehaviorCommand(
                        leftWinkCommand
                    )
                }

                controlButton(
                    title: "Right Wink",
                    systemImage:
                        "arrow.right.circle"
                ) {

                    handleBehaviorCommand(
                        rightWinkCommand
                    )
                }
            }

            controlButton(
                title:
                    "Stop / Eyes Open",
                systemImage:
                    "eye.fill"
            ) {

                // S is the universal
                // OH-SHIT button.

                stopPerformance(
                    sendStop: false
                )

                sendToCurrentTarget(
                    "S"
                )
            }
        }
    }

    // MARK: - Control Button Helper

    @ViewBuilder
    private func controlButton(
        title: String,
        systemImage: String,
        prominent: Bool = false,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {

        if prominent {

            Button(
                action: action
            ) {

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
            .disabled(disabled)

        } else {

            Button(
                action: action
            ) {

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
            .disabled(disabled)
        }
    }

    // MARK: - V2 BLE Commands

    /*
     V2 protocol:

     L:<speed>

     R:<speed>

     B:<interval>:<speed>

     I:<transitionInterval>:<minSpeed>:<maxSpeed>

     C:<transitionInterval>:<minSpeed>:<maxSpeed>:<seed>


     Examples:

     L:1.00

     B:3.00:1.00

     I:1.00:0.50:1.50

     C:1.00:0.50:1.50:123456789


     Coordinated Creepy sends the SAME
     random seed and behavior parameters
     to every Creep.

     Once the firmware is updated, all
     Creeps will therefore generate the
     same random sequence.
     */

    private var leftWinkCommand:
        String {

        String(
            format: "L:%.2f",
            winkSpeed
        )
    }

    private var rightWinkCommand:
        String {

        String(
            format: "R:%.2f",
            winkSpeed
        )
    }

    private var blinkCommand:
        String {

        String(
            format: "B:%.2f:%.2f",
            blinkInterval,
            blinkSpeed
        )
    }

    private var independentCreepyCommand:
        String {

        String(
            format:
                "I:%.2f:%.2f:%.2f",
            creepyTransitionInterval,
            creepyMinSpeed,
            creepyMaxSpeed
        )
    }

    private func coordinatedCreepyCommand(
        seed: UInt32
    ) -> String {

        String(
            format:
                "C:%.2f:%.2f:%.2f:%u",
            creepyTransitionInterval,
            creepyMinSpeed,
            creepyMaxSpeed,
            seed
        )
    }

    // MARK: - Command Routing

    private func handleBehaviorCommand(
        _ command: String
    ) {

        // Any new manual command
        // aborts Performance.

        stopPerformance(
            sendStop: false
        )

        sendToCurrentTarget(
            command
        )
    }

    private func sendToCurrentTarget(
        _ command: String
    ) {

        // One connected creep:
        // naturally behave like V1.

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

    private func sendToFleet(
        _ command: String
    ) {

        guard
            bleManager.connectedCount > 1
        else {
            return
        }

        bleManager
            .sendCommandToAll(
                command
            )
    }

    // MARK: - Coordinated Creepy

    private func startCoordinatedCreepy() {

        guard
            fleetOnlyCommandsEnabled
        else {
            return
        }

        stopPerformance(
            sendStop: false
        )

        let seed =
            UInt32.random(
                in:
                    UInt32.min
                    ...
                    UInt32.max
            )

        sendToFleet(
            coordinatedCreepyCommand(
                seed: seed
            )
        )
    }

    // MARK: - Performance

    private func startPerformance() {

        guard
            fleetOnlyCommandsEnabled
        else {
            return
        }

        stopPerformance(
            sendStop: false
        )

        performanceRunning = true

        // Snapshot settings when P begins.
        // Changing Settings midway through
        // the show won't alter an active run.

        let phaseDuration =
            performanceActionDuration

        let repeatingWinkInterval =
            winkInterval

        let leftCommand =
            leftWinkCommand

        let rightCommand =
            rightWinkCommand

        let blink =
            blinkCommand

        let independent =
            independentCreepyCommand

        let coordinated =
            coordinatedCreepyCommand(
                seed:
                    UInt32.random(
                        in:
                            UInt32.min
                            ...
                            UInt32.max
                    )
            )

        performanceTask =
            Task { @MainActor in

                defer {

                    performanceRunning =
                        false

                    performanceTask =
                        nil
                }

                // LEFT WINK PHASE

                bleManager.status =
                    "Performance: Left Wink"

                guard
                    await runRepeatedFleetCommand(
                        leftCommand,
                        every:
                            repeatingWinkInterval,
                        for:
                            phaseDuration
                    )
                else {
                    return
                }

                guard !Task.isCancelled
                else {
                    return
                }

                // RIGHT WINK PHASE

                bleManager.status =
                    "Performance: Right Wink"

                guard
                    await runRepeatedFleetCommand(
                        rightCommand,
                        every:
                            repeatingWinkInterval,
                        for:
                            phaseDuration
                    )
                else {
                    return
                }

                guard !Task.isCancelled
                else {
                    return
                }

                // BLINK PHASE

                sendToFleet(blink)

                bleManager.status =
                    "Performance: Blink"

                guard
                    await sleepSeconds(
                        phaseDuration
                    )
                else {
                    return
                }

                guard !Task.isCancelled
                else {
                    return
                }

                // INDEPENDENT CREEPY PHASE

                sendToFleet(
                    independent
                )

                bleManager.status =
                    "Performance: Independent Creepy"

                guard
                    await sleepSeconds(
                        phaseDuration
                    )
                else {
                    return
                }

                guard !Task.isCancelled
                else {
                    return
                }

                // COORDINATED CREEPY
                //
                // This is the resting/finale
                // state of Performance.
                //
                // It runs indefinitely until
                // S or another command.

                sendToFleet(
                    coordinated
                )

                bleManager.status =
                    "Performance: Coordinated Creepy"
            }
    }

    // Repeated L/R phase used by P.
    //
    // Manual L and R remain ONE wink.
    //
    // Example:
    // 10-second phase / 3-second interval
    // gives approximately three winks.

    @MainActor
    private func runRepeatedFleetCommand(
        _ command: String,
        every interval: Double,
        for duration: Double
    ) async -> Bool {

        let safeInterval =
            max(
                0.25,
                interval
            )

        let safeDuration =
            max(
                0.25,
                duration
            )

        let eventCount =
            max(
                1,
                Int(
                    floor(
                        safeDuration
                        /
                        safeInterval
                    )
                )
            )

        var elapsed = 0.0

        for index in 0..<eventCount {

            guard !Task.isCancelled
            else {
                return false
            }

            sendToFleet(
                command
            )

            if index <
                eventCount - 1 {

                guard
                    await sleepSeconds(
                        safeInterval
                    )
                else {
                    return false
                }

                elapsed +=
                    safeInterval
            }
        }

        // Keep the phase alive for the
        // requested total duration even
        // after its final wink.

        let remaining =
            safeDuration - elapsed

        if remaining > 0 {

            guard
                await sleepSeconds(
                    remaining
                )
            else {
                return false
            }
        }

        return !Task.isCancelled
    }

    private func sleepSeconds(
        _ seconds: Double
    ) async -> Bool {

        let safeSeconds =
            max(
                0.01,
                seconds
            )

        let nanoseconds =
            UInt64(
                safeSeconds
                *
                1_000_000_000
            )

        do {

            try await Task.sleep(
                nanoseconds:
                    nanoseconds
            )

            return !Task.isCancelled

        } catch {

            return false
        }
    }

    private func stopPerformance(
        sendStop: Bool
    ) {

        guard
            performanceTask != nil
            ||
            performanceRunning
        else {
            return
        }

        performanceTask?
            .cancel()

        performanceTask =
            nil

        performanceRunning =
            false

        if sendStop {

            // P always runs against ALL.
            bleManager
                .sendCommandToAll(
                    "S"
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
                bleManager
                    .isConnecting(
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

            bleManager
                .startScanning()

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

// MARK: - Settings Screen

private struct CreepSettingsView:
    View {

    @AppStorage(
        CreepSettingKeys.winkInterval
    )
    private var winkInterval =
        CreepDefaults.winkInterval

    @AppStorage(
        CreepSettingKeys.winkSpeed
    )
    private var winkSpeed =
        CreepDefaults.winkSpeed

    @AppStorage(
        CreepSettingKeys.blinkInterval
    )
    private var blinkInterval =
        CreepDefaults.blinkInterval

    @AppStorage(
        CreepSettingKeys.blinkSpeed
    )
    private var blinkSpeed =
        CreepDefaults.blinkSpeed

    @AppStorage(
        CreepSettingKeys.creepyTransitionInterval
    )
    private var creepyTransitionInterval =
        CreepDefaults.creepyTransitionInterval

    @AppStorage(
        CreepSettingKeys.creepyMinSpeed
    )
    private var creepyMinSpeed =
        CreepDefaults.creepyMinSpeed

    @AppStorage(
        CreepSettingKeys.creepyMaxSpeed
    )
    private var creepyMaxSpeed =
        CreepDefaults.creepyMaxSpeed

    @AppStorage(
        CreepSettingKeys.performanceActionDuration
    )
    private var performanceActionDuration =
        CreepDefaults.performanceActionDuration

    var body: some View {

        Form {

            // MARK: Wink

            Section("Wink") {

                settingRow(
                    title:
                        "Wink Interval",
                    value:
                        $winkInterval,
                    range:
                        1.0...10.0,
                    step:
                        0.5,
                    defaultValue:
                        CreepDefaults
                            .winkInterval,
                    display: {
                        String(
                            format:
                                "%.1f sec",
                            $0
                        )
                    }
                )

                Text(
                    "Wink Interval applies when Performance repeats Left/Right Wink. Manual L and R remain single winks."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )

                settingRow(
                    title:
                        "Wink Speed",
                    value:
                        $winkSpeed,
                    range:
                        0.5...2.0,
                    step:
                        0.1,
                    defaultValue:
                        CreepDefaults
                            .winkSpeed,
                    display:
                        speedDisplay
                )
            }

            // MARK: Blink

            Section("Blink") {

                settingRow(
                    title:
                        "Blink Interval",
                    value:
                        $blinkInterval,
                    range:
                        1.0...10.0,
                    step:
                        0.5,
                    defaultValue:
                        CreepDefaults
                            .blinkInterval,
                    display: {
                        String(
                            format:
                                "%.1f sec",
                            $0
                        )
                    }
                )

                settingRow(
                    title:
                        "Blink Speed",
                    value:
                        $blinkSpeed,
                    range:
                        0.5...2.0,
                    step:
                        0.1,
                    defaultValue:
                        CreepDefaults
                            .blinkSpeed,
                    display:
                        speedDisplay
                )
            }

            // MARK: Creepy

            Section("Creepy") {

                settingRow(
                    title:
                        "Transition Interval",
                    value:
                        $creepyTransitionInterval,
                    range:
                        0.25...5.0,
                    step:
                        0.25,
                    defaultValue:
                        CreepDefaults
                            .creepyTransitionInterval,
                    display: {
                        String(
                            format:
                                "%.2f sec",
                            $0
                        )
                    }
                )

                settingRow(
                    title:
                        "Minimum Speed",
                    value:
                        $creepyMinSpeed,
                    range:
                        0.25...2.0,
                    step:
                        0.1,
                    defaultValue:
                        CreepDefaults
                            .creepyMinSpeed,
                    display:
                        speedDisplay
                )
                .onChange(
                    of:
                        creepyMinSpeed
                ) { _, newValue in

                    if newValue >
                        creepyMaxSpeed {

                        creepyMaxSpeed =
                            newValue
                    }
                }

                settingRow(
                    title:
                        "Maximum Speed",
                    value:
                        $creepyMaxSpeed,
                    range:
                        0.25...2.5,
                    step:
                        0.1,
                    defaultValue:
                        CreepDefaults
                            .creepyMaxSpeed,
                    display:
                        speedDisplay
                )
                .onChange(
                    of:
                        creepyMaxSpeed
                ) { _, newValue in

                    if newValue <
                        creepyMinSpeed {

                        creepyMinSpeed =
                            newValue
                    }
                }
            }

            // MARK: Performance

            Section("Performance") {

                settingRow(
                    title:
                        "Action Duration",
                    value:
                        $performanceActionDuration,
                    range:
                        2.0...30.0,
                    step:
                        1.0,
                    defaultValue:
                        CreepDefaults
                            .performanceActionDuration,
                    display: {
                        String(
                            format:
                                "%.0f sec",
                            $0
                        )
                    }
                )

                Text(
                    "Performance runs Left Wink → Right Wink → Blink → Independent Creepy for this many seconds each, then settles on Coordinated Creepy until Stop."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }

            // MARK: Restore All

            Section {

                Button(
                    role: .destructive
                ) {

                    restoreAllDefaults()

                } label: {

                    Label(
                        "Restore All Defaults",
                        systemImage:
                            "arrow.counterclockwise"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                }
            }
        }
        .navigationTitle(
            "Settings"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }

    // MARK: - Setting Row

    private func settingRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        defaultValue: Double,
        display:
            @escaping (Double) -> String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            HStack {

                Text(title)

                Spacer()

                Text(
                    display(
                        value.wrappedValue
                    )
                )
                .monospacedDigit()
                .foregroundStyle(
                    .secondary
                )

                Button("Reset") {

                    value.wrappedValue =
                        defaultValue
                }
                .buttonStyle(
                    .borderless
                )
            }

            Slider(
                value: value,
                in: range,
                step: step
            )
        }
        .padding(
            .vertical,
            2
        )
    }

    // MARK: - Speed Display

    private func speedDisplay(
        _ value: Double
    ) -> String {

        if abs(
            value - 1.0
        ) < 0.001 {

            return "Normal"
        }

        return String(
            format:
                "%.1f×",
            value
        )
    }

    // MARK: - Restore Defaults

    private func restoreAllDefaults() {

        winkInterval =
            CreepDefaults
                .winkInterval

        winkSpeed =
            CreepDefaults
                .winkSpeed

        blinkInterval =
            CreepDefaults
                .blinkInterval

        blinkSpeed =
            CreepDefaults
                .blinkSpeed

        creepyTransitionInterval =
            CreepDefaults
                .creepyTransitionInterval

        creepyMinSpeed =
            CreepDefaults
                .creepyMinSpeed

        creepyMaxSpeed =
            CreepDefaults
                .creepyMaxSpeed

        performanceActionDuration =
            CreepDefaults
                .performanceActionDuration
    }
}

#Preview {

    ContentView()
}
