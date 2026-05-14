import SwiftUI
import RealityKit

// MARK: - Home View

struct HomeView: View {
    @State private var selectedScanType:    ScanType?
    @State private var pendingScanType:     ScanType?
    @State private var captureScanType:     ScanType?
    @State private var showLiDARAlert       = false
    @State private var captureSessionName   = ""
    @State private var completedSession:    ScanSession?
    @State private var pastSessions:        [ScanSession] = []

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                (isDark ? Color.black : Color(red: 0.95, green: 0.98, blue: 0.96))
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroHeader
                            .padding(.bottom, 28)

                        VStack(spacing: 22) {
                            bodyPartSection
                            pastSessionsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                    }
                }
            }
            .onAppear { reloadPastSessions() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 7) {
                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(medGreen)
                        Text("ProstheScan")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isDark ? .white : Color(.label))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.subheadline)
                            .foregroundStyle(medGreen)
                    }
                }
            }
            .alert("LiDAR Required", isPresented: $showLiDARAlert) {
                Button("OK", role: .cancel) { selectedScanType = nil }
            } message: {
                Text("3D scanning requires a LiDAR sensor (iPhone 12 Pro or later). This device does not support 3D capture.")
            }
            .sheet(item: $pendingScanType) { type in
                ScanNamePromptView(scanType: type) { name in
                    captureSessionName = name
                    pendingScanType    = nil
                    captureScanType    = type
                } onCancel: {
                    pendingScanType  = nil
                    selectedScanType = nil
                }
            }
            .fullScreenCover(item: $captureScanType) { type in
                LiDARCaptureView(
                    scanType:    type,
                    sessionName: captureSessionName
                ) { folderURL in
                    let session = ScanSession(
                        type:   type,
                        label:  captureSessionName,
                        folder: folderURL,
                        date:   Date()
                    )
                    ScanManager.createMeasurementsFile(in: folderURL)
                    captureScanType  = nil
                    completedSession = session
                } onCancel: {
                    captureScanType  = nil
                    selectedScanType = nil
                }
            }
            .sheet(item: $completedSession, onDismiss: {
                selectedScanType = nil
                reloadPastSessions()
            }) { session in
                ScanCompleteSheet(session: session)
            }
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.04, green: 0.22, blue: 0.14), Color(red: 0.08, green: 0.14, blue: 0.10)]
                    : [medGreenDark, medGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)

            Circle()
                .fill(medGreenLight.opacity(isDark ? 0.12 : 0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 180, y: -40)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: "waveform.path.ecg.rectangle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ProstheScan")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("Clinical Imaging System")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.70))
                    }
                    Spacer()
                }
                Text("Select the anatomical region to scan")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.80))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Body Part Grid

    private var bodyPartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Anatomical Region", icon: "person.crop.rectangle.fill")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(ScanType.allCases) { type in
                    MedicalBodyPartCard(
                        scanType:   type,
                        isSelected: selectedScanType == type,
                        isDark:     isDark
                    )
                    .onTapGesture { handleTap(type) }
                }
            }
        }
    }

    // MARK: - Tap Handler

    private func handleTap(_ type: ScanType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedScanType = type
        }
        guard deviceHasLiDAR else {
            showLiDARAlert = true
            return
        }
        pendingScanType = type
    }

    // MARK: - Past Sessions

    @ViewBuilder
    private var pastSessionsSection: some View {
        if !pastSessions.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Past Scans", icon: "clock.arrow.circlepath")

                VStack(spacing: 10) {
                    ForEach(pastSessions) { session in
                        Button {
                            completedSession = session
                        } label: {
                            pastSessionRow(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func pastSessionRow(_ session: ScanSession) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(medGreen.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: session.type.icon)
                    .foregroundStyle(medGreen)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.label))
                Text(session.date.formatted(.dateTime.day().month().year().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if ReconstructionService.hasExistingModel(in: session.folder) {
                Image(systemName: "cube.transparent.fill")
                    .foregroundStyle(medGreen)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color(red: 0.11, green: 0.14, blue: 0.12) : .white)
        )
        .shadow(color: isDark ? .clear : .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func reloadPastSessions() {
        let fm   = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let entries = try? fm.contentsOfDirectory(
            at: docs,
            includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey],
            options: .skipsHiddenFiles
        ) else {
            pastSessions = []
            return
        }

        let sessions: [ScanSession] = entries.compactMap { url in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return nil }
            let name = url.lastPathComponent
            let parts = name.split(separator: "_", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count >= 2,
                  let type = ScanType(rawValue: String(parts[0]))
            else { return nil }

            let label: String
            let dateString: String
            if parts.count == 3 {
                label = String(parts[1]).replacingOccurrences(of: "-", with: " ")
                dateString = String(parts[2])
            } else {
                label = ""
                dateString = String(parts[1])
            }

            let date = DateFormatter.sessionFormat.date(from: dateString)
                ?? (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate)
                ?? Date()

            return ScanSession(type: type, label: label, folder: url, date: date)
        }

        pastSessions = sessions.sorted { $0.date > $1.date }
    }

    private func sectionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(medGreen)
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Medical Body Part Card

struct MedicalBodyPartCard: View {
    let scanType:   ScanType
    let isSelected: Bool
    let isDark:     Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        isSelected
                            ? LinearGradient(colors: [medGreenLight, medGreen],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [medGreen.opacity(isDark ? 0.20 : 0.10),
                                                      medGreen.opacity(isDark ? 0.12 : 0.06)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 50, height: 50)
                Image(systemName: scanType.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : medGreen)
            }
            .shadow(
                color: isSelected ? medGreen.opacity(isDark ? 0.55 : 0.30) : .clear,
                radius: 10, x: 0, y: 4
            )

            Text(scanType.rawValue)
                .font(.caption.weight(.bold))
                .tracking(0.2)
                .foregroundStyle(isSelected
                                 ? (isDark ? medGreenLight : medGreenDark)
                                 : Color(.label))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(cardBackground(selected: isSelected, isDark: isDark))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? LinearGradient(colors: [medGreenLight.opacity(0.8), medGreen.opacity(0.5)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: isSelected
                ? medGreen.opacity(isDark ? 0.25 : 0.12)
                : (isDark ? .clear : .black.opacity(0.05)),
            radius: isSelected ? 14 : 6,
            x: 0, y: isSelected ? 5 : 2
        )
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
    }

    private func cardBackground(selected: Bool, isDark: Bool) -> some ShapeStyle {
        if selected {
            return AnyShapeStyle(isDark
                ? Color(red: 0.08, green: 0.18, blue: 0.12)
                : Color(red: 0.93, green: 0.99, blue: 0.96))
        }
        return AnyShapeStyle(isDark
            ? Color(red: 0.11, green: 0.14, blue: 0.12)
            : Color.white)
    }
}
