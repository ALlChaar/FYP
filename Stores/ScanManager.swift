import Foundation

enum ScanManager {
    static func measurementsURL(in folder: URL) -> URL {
        folder.appendingPathComponent("measurements.txt")
    }

    static func createMeasurementsFile(in folder: URL) {
        let url = measurementsURL(in: folder)
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try? "".write(to: url, atomically: true, encoding: .utf8)
    }
}
