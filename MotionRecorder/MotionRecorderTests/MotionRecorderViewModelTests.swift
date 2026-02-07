import XCTest
@testable import MotionRecorder

@MainActor
final class MotionRecorderViewModelTests: XCTestCase {

    var viewModel: MotionRecorderViewModel!
    var mockMotionService: MockMotionService!
    var mockDatabaseService: MockDatabaseService!
    var mockExportService: MockExportService!

    override func setUp() async throws {
        try await super.setUp()

        mockMotionService = MockMotionService()
        mockDatabaseService = MockDatabaseService()
        mockExportService = MockExportService()

        viewModel = MotionRecorderViewModel(
            motionService: mockMotionService,
            databaseService: mockDatabaseService,
            exportService: mockExportService
        )
    }

    override func tearDown() async throws {
        viewModel = nil
        mockMotionService = nil
        mockDatabaseService = nil
        mockExportService = nil
        try await super.tearDown()
    }

    func testStartRecording_UpdatesState() {
        viewModel.startRecording()

        XCTAssertTrue(viewModel.isRecording)
        XCTAssertTrue(mockMotionService.startRecordingCalled)
        XCTAssertTrue(mockMotionService.isRecording)
    }

    func testStopRecording_UpdatesState() {
        viewModel.startRecording()
        viewModel.stopRecording()

        XCTAssertFalse(viewModel.isRecording)
        XCTAssertTrue(mockMotionService.stopRecordingCalled)
        XCTAssertFalse(mockMotionService.isRecording)
    }

    func testStartRecording_WhenAccelerometerUnavailable_ShowsError() {
        mockMotionService.isAvailable = false

        viewModel.startRecording()

        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Accelerometer"))
    }

    func testExportData_WithRecords_ReturnsURL() async throws {
        let testData = createTestDataPoints(count: 10)
        mockDatabaseService.dataPoints = testData

        let url = try await viewModel.exportData()

        XCTAssertNotNil(url)
        XCTAssertTrue(mockExportService.exportCalled)
        XCTAssertEqual(mockExportService.exportedDataPoints.count, 10)
        XCTAssertNotNil(viewModel.lastExportTime)
    }

    func testExportData_WithNoRecords_ThrowsError() async {
        do {
            _ = try await viewModel.exportData()
            XCTFail("Should throw error when no data to export")
        } catch {
            XCTAssertTrue(error is ExportError)
        }
    }

    func testRefreshStats_LoadsDataFromDatabase() async {
        let testData = createTestDataPoints(count: 5)
        mockDatabaseService.dataPoints = testData

        await viewModel.refreshStats()

        XCTAssertNotNil(viewModel.firstRecordingTime)
        XCTAssertNotNil(viewModel.lastRecordingTime)
        XCTAssertEqual(viewModel.recordCount, 5)
    }

    func testRefreshStats_WithEmptyDatabase_SetsNilValues() async {
        await viewModel.refreshStats()

        XCTAssertNil(viewModel.firstRecordingTime)
        XCTAssertNil(viewModel.lastRecordingTime)
        XCTAssertEqual(viewModel.recordCount, 0)
    }

    func testExportData_UpdatesLastExportTime() async throws {
        let testData = createTestDataPoints(count: 3)
        mockDatabaseService.dataPoints = testData

        let beforeExport = Date()
        _ = try await viewModel.exportData()
        let afterExport = Date()

        XCTAssertNotNil(viewModel.lastExportTime)
        XCTAssertTrue(viewModel.lastExportTime! >= beforeExport)
        XCTAssertTrue(viewModel.lastExportTime! <= afterExport)
    }

    func testExportData_FetchesDataSinceLastExport() async throws {
        let oldData = createTestDataPoints(count: 5, startTimestamp: 100)
        let newData = createTestDataPoints(count: 3, startTimestamp: 200)

        mockDatabaseService.dataPoints = oldData + newData

        viewModel.lastExportTime = Date(timeIntervalSinceReferenceDate: 150)

        _ = try await viewModel.exportData()

        XCTAssertEqual(mockExportService.exportedDataPoints.count, 3)
    }

    private func createTestDataPoints(count: Int, startTimestamp: TimeInterval = 1) -> [MotionDataPoint] {
        (0..<count).map { index in
            MotionDataPoint(
                timestamp: startTimestamp + Double(index),
                x: Double.random(in: -1...1),
                y: Double.random(in: -1...1),
                z: Double.random(in: -1...1)
            )
        }
    }
}
