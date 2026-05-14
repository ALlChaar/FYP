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
        case .hand: return "Place the hand flat or in resting position. Walk slowly around it."
        case .nose: return "Position the face forward. Slowly orbit the scanner around the nose."
        case .ear:  return "Tilt the head sideways. Slowly orbit the scanner around the ear."
        }
    }
}
