import SwiftUI

struct ScanCompleteSheet: View {
    let session: ScanSession

    @Environment(\.dismiss) private var dismiss
    @State private var measurements  = ""
    @State private var showShareSheet = false

    private var measurementsURL: URL { ScanManager.measurementsURL(in: session.folder) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    // Success header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(colors: [medGreenLight, medGreen],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: medGreen.opacity(0.40), radius: 14, x: 0, y: 5)

                        Text("Scan Complete")
                            .font(.title2.weight(.bold))

                        Text(session.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(session.date.formatted(.dateTime.day().month().year().hour().minute()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Measurements editor
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Measurements", systemImage: "ruler.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(medGreen)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        TextEditor(text: $measurements)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 140)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color(.separator), lineWidth: 0.5)
                            )

                        Text("Optional — enter measurements, notes, or patient info.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            saveMeasurements()
                            showShareSheet = true
                        } label: {
                            Label("Export via AirDrop", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(medGreen, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Button("Done") {
                            saveMeasurements()
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Session Ready")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [session.folder])
            }
            .onAppear { loadMeasurements() }
        }
        .tint(medGreen)
    }

    private func loadMeasurements() {
        measurements = (try? String(contentsOf: measurementsURL, encoding: .utf8)) ?? ""
    }

    private func saveMeasurements() {
        try? measurements.write(to: measurementsURL, atomically: true, encoding: .utf8)
    }
}
