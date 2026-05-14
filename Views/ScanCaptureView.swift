// LiDARCaptureView.swift
// Full-screen ObjectCapture UI using Apple's RealityKit ObjectCaptureSession.
//
// ObjectCaptureSession uses @Observable (not ObservableObject), so it is stored
// in a plain @State var. CaptureState contains a .failed(Error) associated value
// that prevents Equatable conformance, so we map it to a local Phase enum for
// onChange tracking.
//
// State machine:
//   .initializing → .ready → .detecting → .capturing → .finishing → .completed

import SwiftUI
import RealityKit

@Observable
@MainActor
final class CaptureModel {
    var session: ObjectCaptureSession?
    var sessionFolderURL: URL?
    var errorMessage: String?
    var capturedCount = 0
    var initTimedOut = false
    var hasStartedDetecting = false
}

struct LiDARCaptureView: View {

    let scanType:    ScanType
    let sessionName: String
    let onComplete:  (URL) -> Void
    let onCancel:    () -> Void

    @State private var model = CaptureModel()

    // MARK: - Local Equatable phase mirror
    // CaptureState has .failed(Error) which prevents Equatable conformance,
    // so onChange(of:) cannot use it directly. We map to this flat enum.
    private enum Phase: Equatable {
        case notStarted, initializing, ready, detecting, capturing, finishing, completed, failed
        init(_ state: ObjectCaptureSession.CaptureState) {
            switch state {
            case .initializing: self = .initializing
            case .ready:        self = .ready
            case .detecting:    self = .detecting
            case .capturing:    self = .capturing
            case .finishing:    self = .finishing
            case .completed:    self = .completed
            case .failed:       self = .failed
            @unknown default:   self = .failed
            }
        }
    }

    private var phase: Phase {
        guard let session = model.session else { return .notStarted }
        return Phase(session.state)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let msg = model.errorMessage {
                errorView(message: msg)
            } else {
#if targetEnvironment(simulator)
                simulatorPlaceholder
#else
                if let session = model.session {
                    ObjectCaptureView(session: session)
                        .ignoresSafeArea()
                } else {
                    Color.black.ignoresSafeArea()
                }
#endif
                overlayControls
            }
        }
        .onAppear { startSession() }
        .task { await observeSessionState() }
        // Timeout: if still initializing after 12 s, surface a helpful error
        .task {
            try? await Task.sleep(for: .seconds(20))
            guard phase == .initializing || phase == .notStarted else { return }
            model.initTimedOut = true
            model.errorMessage = """
            LiDAR sensor did not start.

            Try:
            • Hard-restart the device (power off / on)
            • Delete & reinstall the app to reset camera permission
            • Ensure the LiDAR window is not covered
            • Good lighting, 20–40 cm from the object

            (This is a known iOS 26 beta issue with ObjectCaptureSession.)
            """
        }
        // Live image count while capturing
        .task(id: phase) {
            guard phase == .capturing else { return }
            while !Task.isCancelled {
                if let imagesDir = model.sessionFolderURL?.appendingPathComponent("Images") {
                    model.capturedCount = countImages(in: imagesDir)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: - Overlay

    private var overlayControls: some View {
        VStack {
            // Top bar
            HStack {
                Spacer()
                Button {
                    if phase != .completed && phase != .failed {
                        model.session?.cancel()
                    }
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }

            Spacer()

            // Context-sensitive bottom bar
            bottomActionBar
                .padding(.bottom, 48)
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var bottomActionBar: some View {
        switch phase {
        case .notStarted, .initializing:
            statusPill(label: "Initializing…")

        case .ready:
            VStack(spacing: 12) {
                statusPill(label: "Ready — point at the \(scanType.rawValue.lowercased())")
                actionButton(title: "Start Detecting", icon: "viewfinder") {
                    _ = model.session?.startDetecting()
                }
            }

        case .detecting:
            VStack(spacing: 12) {
                statusPill(label: "Adjust the box around the \(scanType.rawValue.lowercased())")
                actionButton(title: "Start Capture", icon: "camera.fill") {
                    model.session?.startCapturing()
                }
            }

        case .capturing:
            VStack(spacing: 12) {
                statusPill(label: "\(model.capturedCount) images captured")

                Text(scanType.instruction)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .shadow(color: .black.opacity(0.6), radius: 4)

                if let session = model.session, canFinishNow(session: session) {
                    actionButton(title: "Finish", icon: "checkmark.circle.fill") {
                        session.finish()
                    }
                }
            }

        case .finishing:
            statusPill(label: "Processing…")

        case .completed, .failed:
            EmptyView()
        }
    }

    // MARK: - Sub-views

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(medGreen, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func statusPill(label: String) -> some View {
        HStack(spacing: 10) {
            ProgressView().tint(.white)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.black.opacity(0.50), in: Capsule())
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.red)
            Text("Capture Error")
                .font(.title3.weight(.bold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Close", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(medGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var simulatorPlaceholder: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "camera.metering.unknown")
                    .font(.system(size: 64))
                    .foregroundStyle(medGreen)
                Text("LiDAR unavailable on Simulator")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Run on a physical iPhone 12 Pro or later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - State Observation
    // Uses session.stateUpdates (AsyncSequence) — fires in the session's own
    // update cycle, avoiding the race condition that breaks onChange(of:).
    @MainActor
    private func observeSessionState() async {
        // Wait until the session has been instantiated by startSession().
        while model.session == nil {
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }
        }
        guard let session = model.session else { return }

        // Handle the *current* state once before subscribing — the stateUpdates
        // AsyncSequence only delivers future transitions, so if .ready fired
        // before this task attached we would otherwise miss it.
        handle(state: session.state, session: session)

        for await state in session.stateUpdates {
            handle(state: state, session: session)
        }
    }

    @MainActor
    private func handle(state: ObjectCaptureSession.CaptureState,
                        session: ObjectCaptureSession) {
        switch state {
        case .ready:
            // Auto-advance to detecting so the bounding box appears.
            // Guard against double-firing: the AsyncSequence and the initial
            // state read can both deliver .ready, and calling startDetecting()
            // twice raises invalidState("running").
            guard !model.hasStartedDetecting else { break }
            model.hasStartedDetecting = true
            if !session.startDetecting() {
                // Don't show an error — the state machine may already have
                // advanced. We'll see the real state in the next update.
                model.hasStartedDetecting = false
            }
        case .completed:
            if let folder = model.sessionFolderURL { onComplete(folder) }
        case .failed(let error):
            model.errorMessage = error.localizedDescription
        default:
            break
        }
    }

    // MARK: - Session Setup

    private func startSession() {
        // Avoid re-entering if the view rebuilds while the session is alive.
        guard model.session == nil else { return }

        guard ObjectCaptureSession.isSupported else {
            model.errorMessage = "This device does not support Object Capture. A LiDAR-equipped iPhone/iPad is required."
            return
        }

        let fm   = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let date     = DateFormatter.sessionFormat.string(from: Date())
        let label    = sessionName.trimmingCharacters(in: .whitespaces)
        let namePart = label.isEmpty ? "" : "_\(label.replacingOccurrences(of: " ", with: "-"))"
        let folder   = "\(scanType.rawValue)\(namePart)_\(date)"

        let folderURL    = docs.appendingPathComponent(folder,      isDirectory: true)
        let imagesURL    = folderURL.appendingPathComponent("Images",    isDirectory: true)
        let snapshotsURL = folderURL.appendingPathComponent("Snapshots", isDirectory: true)

        do {
            try fm.createDirectory(at: imagesURL,    withIntermediateDirectories: true)
            try fm.createDirectory(at: snapshotsURL, withIntermediateDirectories: true)
        } catch {
            model.errorMessage = "Could not create session folder:\n\(error.localizedDescription)"
            return
        }

        model.sessionFolderURL = folderURL

        var config                  = ObjectCaptureSession.Configuration()
        config.checkpointDirectory  = snapshotsURL
        config.isOverCaptureEnabled = true

        let newSession = ObjectCaptureSession()
        newSession.start(imagesDirectory: imagesURL, configuration: config)

        if case let .failed(error) = newSession.state {
            model.errorMessage = "Could not start LiDAR session:\n\(error.localizedDescription)"
            return
        }

        model.session = newSession
    }

    private func canFinishNow(session: ObjectCaptureSession) -> Bool {
        if scanType.requiresFullScan {
            return session.userCompletedScanPass
        }
        return session.userCompletedScanPass
            || model.capturedCount >= scanType.minImagesForHalfScan
    }

    // MARK: - Image Count

    private func countImages(in directory: URL) -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return 0 }
        return enumerator.compactMap { $0 as? URL }.filter {
            let ext = $0.pathExtension.lowercased()
            return ext == "heic" || ext == "jpg" || ext == "jpeg"
        }.count
    }
}
