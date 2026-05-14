import SwiftUI

struct ScanNamePromptView: View {
    let scanType: ScanType
    let onStart:  (String) -> Void
    let onCancel: () -> Void

    @State private var nameInput = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [medGreenLight, medGreen],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                        Image(systemName: scanType.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: medGreen.opacity(0.35), radius: 12, x: 0, y: 5)

                    Text("Scan \(scanType.rawValue)")
                        .font(.title2.weight(.bold))

                    Text(scanType.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Session Label (optional)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    TextField("e.g. Patient ID or name", text: $nameInput)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(fieldFocused ? medGreen : Color.clear, lineWidth: 1.5)
                        )
                        .focused($fieldFocused)
                        .submitLabel(.done)
                        .onSubmit { startCapture() }
                }

                VStack(spacing: 12) {
                    Button(action: startCapture) {
                        Label("Start 3D Scan", systemImage: "dot.scope")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(medGreen, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button("Cancel", role: .cancel, action: onCancel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 36)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { fieldFocused = true }
    }

    private func startCapture() {
        onStart(nameInput.trimmingCharacters(in: .whitespaces))
    }
}
