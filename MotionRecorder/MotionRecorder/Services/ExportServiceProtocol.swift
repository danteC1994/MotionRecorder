import Foundation

protocol ExportServiceProtocol: Sendable {
    func exportToCSV(dataPoints: [MotionDataPoint]) async throws -> URL
}
