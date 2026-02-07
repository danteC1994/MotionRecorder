import Foundation
import SwiftUI

@MainActor
@Observable
final class MotionRecorderViewModel {

    var firstRecordingTime: Date?
    var lastRecordingTime: Date?
    var lastExportTime: Date?
    var isRecording: Bool = false
    var recordCount: Int = 0
    var errorMessage: String?

    private let motionService: MotionServiceProtocol
    private let databaseService: DatabaseServiceProtocol
    private let exportService: ExportServiceProtocol

    private var dataBuffer: [MotionDataPoint] = []
    private let bufferLock = NSLock()

    init(
        motionService: MotionServiceProtocol,
        databaseService: DatabaseServiceProtocol,
        exportService: ExportServiceProtocol
    ) {
        self.motionService = motionService
        self.databaseService = databaseService
        self.exportService = exportService
    }

    convenience init() throws {
        let databaseService = try DatabaseService()
        try databaseService.initialize()

        self.init(
            motionService: MotionService(),
            databaseService: databaseService,
            exportService: ExportService()
        )
    }

    func startRecording() {
        guard !isRecording else { return }
        guard motionService.isAccelerometerAvailable() else {
            errorMessage = "Accelerometer not available on this device"
            return
        }

        motionService.startRecording { [weak self] dataPoint in
            self?.handleMotionData(dataPoint)
        }

        isRecording = true
        startBufferFlushTimer()
    }

    func stopRecording() {
        guard isRecording else { return }

        motionService.stopRecording()
        isRecording = false

        Task {
            await flushBuffer()
        }
    }

    func exportData() async throws -> URL {
        let sinceTimestamp = lastExportTime?.timeIntervalSinceReferenceDate ?? 0
        let dataPoints = try await databaseService.fetchDataSince(sinceTimestamp)

        guard !dataPoints.isEmpty else {
            throw ExportError.noDataToExport
        }

        let fileURL = try await exportService.exportToCSV(dataPoints: dataPoints)

        lastExportTime = Date()
        UserDefaults.standard.set(lastExportTime?.timeIntervalSinceReferenceDate, forKey: Constants.UserDefaultsKeys.lastExportTime)

        return fileURL
    }

    func refreshStats() async {
        do {
            firstRecordingTime = try await databaseService.getFirstRecordingTime()
            lastRecordingTime = try await databaseService.getLastRecordingTime()
            recordCount = try await databaseService.getRecordCount()

            if let savedExportTime = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.lastExportTime) as? TimeInterval {
                lastExportTime = Date(timeIntervalSinceReferenceDate: savedExportTime)
            }
        } catch {
            errorMessage = "Failed to refresh stats: \(error.localizedDescription)"
        }
    }

    func initialize() async {
        await refreshStats()
    }

    private func handleMotionData(_ dataPoint: MotionDataPoint) {
        bufferLock.lock()
        dataBuffer.append(dataPoint)
        let shouldFlush = dataBuffer.count >= Constants.batchInsertSize
        bufferLock.unlock()

        if shouldFlush {
            Task {
                await flushBuffer()
            }
        }
    }

    private func flushBuffer() async {
        bufferLock.lock()
        let pointsToInsert = dataBuffer
        dataBuffer.removeAll()
        bufferLock.unlock()

        guard !pointsToInsert.isEmpty else { return }

        do {
            try await databaseService.insertBatch(pointsToInsert)

            if let lastPoint = pointsToInsert.last {
                lastRecordingTime = lastPoint.date
            }

            recordCount += pointsToInsert.count
        } catch {
            errorMessage = "Failed to save data: \(error.localizedDescription)"
        }
    }

    private func startBufferFlushTimer() {
        Task {
            while isRecording {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await flushBuffer()
            }
        }
    }
}

enum ExportError: LocalizedError {
    case noDataToExport

    var errorDescription: String? {
        switch self {
        case .noDataToExport:
            return "No new data to export since last export"
        }
    }
}
