import Foundation
@testable import MotionRecorder

final class MockExportService: ExportServiceProtocol {
    var shouldThrowError = false
    var exportedDataPoints: [MotionDataPoint] = []
    var exportCalled = false

    func exportToCSV(dataPoints: [MotionDataPoint]) async throws -> URL {
        exportCalled = true

        if shouldThrowError {
            throw MockError.exportFailed
        }

        exportedDataPoints = dataPoints

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_export.csv")
        return fileURL
    }

    enum MockError: Error {
        case exportFailed
    }
}
