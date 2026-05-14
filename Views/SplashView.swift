import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    @State private var logoScale:   CGFloat = 0.6
    @State private var logoOpacity: Double  = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 14
    @State private var taglineOpacity: Double = 0
    @State private var ringScale:   CGFloat = 0.8
    @State private var ringOpacity: Double  = 0

    var body: some View {
        ZStack {
            // Background — same gradient as the rest of the app
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.48, blue: 0.30), // medGreenDark
                    Color(red: 0.16, green: 0.64, blue: 0.41), // medGreen
                    Color(red: 0.24, green: 0.78, blue: 0.52)  // medGreenLight
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle radial glow behind the logo
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)

            VStack(spacing: 18) {

                ZStack {
                    // Ring around the icon
                    Circle()
                        .strokeBorder(Color.white.opacity(0.30), lineWidth: 2)
                        .frame(width: 168, height: 168)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // App logo
                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 6) {
                    Text("ProstheScan")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .opacity(titleOpacity)
                        .offset(y: titleOffset)

                    Text("Clinical Imaging System")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.85))
                        .textCase(.uppercase)
                        .opacity(taglineOpacity)
                }
                .padding(.top, 8)
            }

            VStack {
                Spacer()
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    Text("Initializing scanner…")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .opacity(taglineOpacity)
                .padding(.bottom, 48)
            }
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.55)) {
            logoOpacity = 1
            logoScale   = 1
            ringOpacity = 1
            ringScale   = 1
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.25)) {
            titleOpacity = 1
            titleOffset  = 0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
            taglineOpacity = 1
        }

        // Hand off to the main UI after the full sequence settles.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            onFinish()
        }
    }
}
