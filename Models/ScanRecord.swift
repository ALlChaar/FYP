import Foundation

struct ScanSession: Identifiable {
    let id    = UUID()
    let type:   ScanType
    let label:  String
    let folder: URL
    let date:   Date

    var displayName: String {
        label.isEmpty ? type.rawValue : "\(type.rawValue) — \(label)"
    }
}
