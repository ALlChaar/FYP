import Foundation

enum ScanType: String, CaseIterable, Identifiable, Codable {
    case hand = "Hand"
    case nose = "Nose"
    case ear  = "Ear"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hand: return "hand.raised.fill"
        case .nose: return "face.smiling.fill"
        case .ear:  return "ear.fill"
        }
    }

    var description: String {
        switch self {
        case .hand: return "Bilateral structure — uses symmetry reconstruction"
        case .nose: return "Non-bilateral — uses AI point cloud completion"
        case .ear:  return "Semi-bilateral — uses symmetry reconstruction"
        }
    }

    var instruction: String {
        switch self {
        case .hand: return "Place the hand flat or in resting position. Walk a full 360° around it."
        case .nose: return "Position the face forward. Slowly orbit 180° in front of the nose."
        case .ear:  return "Tilt the head sideways. Slowly orbit 180° around the side of the head."
        }
    }

    /// Hand requires a full 360° pass. Nose / ear are accessible from one side only,
    /// so the user finishes after ~180° of coverage.
    var requiresFullScan: Bool {
        switch self {
        case .hand: return true
        case .nose, .ear: return false
        }
    }

    /// Minimum image count before the user may tap Finish on a half-orbit scan.
    var minImagesForHalfScan: Int { 12 }
}
