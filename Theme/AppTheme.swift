import SwiftUI

// Global design tokens — used across all views
let medGreen      = Color(red: 0.16, green: 0.64, blue: 0.41)
let medGreenDark  = Color(red: 0.09, green: 0.48, blue: 0.30)
let medGreenLight = Color(red: 0.24, green: 0.78, blue: 0.52)

enum AppTheme {
    static let green      = medGreen
    static let greenLight = medGreenLight
    static let greenDark  = medGreenDark
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(medGreen)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(medGreen)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(medGreenLight.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
