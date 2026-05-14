import Foundation
import ARKit

/// True when the device has a LiDAR scanner (iPhone 12 Pro or later).
var deviceHasLiDAR: Bool {
    ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
}

extension DateFormatter {
    static let sessionFormat: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return f
    }()
}
