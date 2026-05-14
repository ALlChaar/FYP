import SwiftUI

struct SettingsView: View {
    @AppStorage("exportFormat")    private var exportFormat    = "heic"
    @AppStorage("hapticFeedback") private var hapticFeedback = true

    var body: some View {
        Form {
            Section("Export") {
                Picker("Image Format", selection: $exportFormat) {
                    Text("HEIC (Recommended)").tag("heic")
                    Text("JPEG").tag("jpeg")
                }
                Text("HEIC preserves depth data and is smaller. Use JPEG only for compatibility.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Haptics") {
                Toggle("Haptic Feedback", isOn: $hapticFeedback)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Pipeline", value: "3D Scan (LiDAR) → Mac Reconstruction")
            }

            Section("Instructions") {
                Text("""
                1. Select an anatomical region (Hand, Nose, or Ear)
                2. Optionally enter a session label
                3. Scan using the guided LiDAR UI
                4. Add measurements or notes after scanning
                5. Export the capture folder to Mac via AirDrop
                6. Run reconstruction on Mac for the 3D model
                """)
                .font(.caption)
            }
        }
        .navigationTitle("Settings")
        .tint(medGreen)
    }
}
