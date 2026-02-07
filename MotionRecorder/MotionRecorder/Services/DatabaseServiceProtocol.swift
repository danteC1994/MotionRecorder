import Foundation

protocol DatabaseServiceProtocol: Sendable {
    func initialize() throws
    func insert(_ dataPoint: MotionDataPoint) async throws
    func insertBatch(_ dataPoints: [MotionDataPoint]) async throws
    func fetchDataSince(_ timestamp: TimeInterval) async throws -> [MotionDataPoint]
    func getFirstRecordingTime() async throws -> Date?
    func getLastRecordingTime() async throws -> Date?
    func getRecordCount() async throws -> Int
}
