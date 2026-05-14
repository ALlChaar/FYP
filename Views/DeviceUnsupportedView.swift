import SwiftUI

struct DeviceUnsupportedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.green)

            Text("LiDAR Required")
                .font(.title.bold())

            Text("ProstheScan requires an iPhone with LiDAR Scanner\n(iPhone 12 Pro or newer).")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).ignoresSafeArea())
    }
}
