import Foundation
import RealityKit

/// Runs Apple's on-device PhotogrammetrySession to turn a folder of captured
/// images into a USDZ model file. Output is written next to the Images folder
/// at <scanFolder>/Model.usdz so it stays inside the app's container.
@Observable
@MainActor
final class ReconstructionService {

    enum Status: Equatable {
        case idle
        case unsupported
        case running(progress: Double)
        case completed(URL)
        case failed(String)
    }

    private(set) var status: Status = .idle
    private var task: Task<Void, Never>?

    static let modelFileName = "Model.usdz"

    static func modelURL(in scanFolder: URL) -> URL {
        scanFolder.appendingPathComponent(modelFileName)
    }

    static func hasExistingModel(in scanFolder: URL) -> Bool {
        FileManager.default.fileExists(atPath: modelURL(in: scanFolder).path)
    }

    func start(scanFolder: URL, detail: PhotogrammetrySession.Request.Detail = .reduced) {
        guard task == nil else { return }

        let imagesFolder = scanFolder.appendingPathComponent("Images", isDirectory: true)
        let outputURL    = Self.modelURL(in: scanFolder)

        guard PhotogrammetrySession.isSupported else {
            status = .unsupported
            return
        }

        // If a model already exists, surface it immediately.
        if FileManager.default.fileExists(atPath: outputURL.path) {
            status = .completed(outputURL)
            return
        }

        status = .running(progress: 0)

        task = Task { [weak self] in
            do {
                var config = PhotogrammetrySession.Configuration()
                config.sampleOrdering     = .sequential
                config.featureSensitivity = .normal
                config.isObjectMaskingEnabled = true

                let session = try PhotogrammetrySession(input: imagesFolder, configuration: config)

                try session.process(requests: [
                    .modelFile(url: outputURL, detail: detail)
                ])

                for try await output in session.outputs {
                    switch output {
                    case .requestProgress(_, let fraction):
                        await MainActor.run { self?.status = .running(progress: fraction) }
                    case .requestComplete:
                        await MainActor.run { self?.status = .completed(outputURL) }
                    case .requestError(_, let error):
                        await MainActor.run { self?.status = .failed(error.localizedDescription) }
                    case .processingComplete:
                        await MainActor.run {
                            if case .completed = self?.status { } else {
                                self?.status = .completed(outputURL)
                            }
                        }
                    case .processingCancelled:
                        await MainActor.run { self?.status = .failed("Reconstruction was cancelled.") }
                    default:
                        break
                    }
                }
            } catch {
                await MainActor.run { self?.status = .failed(error.localizedDescription) }
            }
            await MainActor.run { self?.task = nil }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        status = .idle
    }
}
