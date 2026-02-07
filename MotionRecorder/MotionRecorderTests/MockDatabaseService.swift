import Foundation
@testable import MotionRecorder

final class MockDatabaseService: DatabaseServiceProtocol {
    var dataPoints: [MotionDataPoint] = []
    var shouldThrowError = false
    var initializeCalled = false
    var insertCalled = false
    var insertBatchCalled = false

    func initialize() throws {
        initializeCalled = true
        if shouldThrowError {
            throw MockError.initializationFailed
        }
    }

    func insert(_ dataPoint: MotionDataPoint) async throws {
        insertCalled = true
        if shouldThrowError {
            throw MockError.insertFailed
        }
        dataPoints.append(dataPoint)
    }

    func insertBatch(_ dataPoints: [MotionDataPoint]) async throws {
        insertBatchCalled = true
        if shouldThrowError {
            throw MockError.insertFailed
        }
        self.dataPoints.append(contentsOf: dataPoints)
    }

    func fetchDataSince(_ timestamp: TimeInterval) async throws -> [MotionDataPoint] {
        if shouldThrowError {
            throw MockError.fetchFailed
        }
        return dataPoints.filter { $0.timestamp > timestamp }
    }

    func getFirstRecordingTime() async throws -> Date? {
        if shouldThrowError {
            throw MockError.fetchFailed
        }
        return dataPoints.first?.date
    }

    func getLastRecordingTime() async throws -> Date? {
        if shouldThrowError {
            throw MockError.fetchFailed
        }
        return dataPoints.last?.date
    }

    func getRecordCount() async throws -> Int {
        if shouldThrowError {
            throw MockError.fetchFailed
        }
        return dataPoints.count
    }

    enum MockError: Error {
        case initializationFailed
        case insertFailed
        case fetchFailed
    }
}
