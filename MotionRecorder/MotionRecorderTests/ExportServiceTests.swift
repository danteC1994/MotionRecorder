import XCTest
@testable import MotionRecorder

final class ExportServiceTests: XCTestCase {

    var exportService: ExportService!

    override func setUp() async throws {
        try await super.setUp()
        exportService = ExportService()
    }

    override func tearDown() async throws {
        exportService = nil
        try await super.tearDown()
    }

    func testExportToCSV_CreatesFile() async throws {
        let dataPoints = createTestDataPoints(count: 3)

        let fileURL = try await exportService.exportToCSV(dataPoints: dataPoints)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportToCSV_HasCorrectHeader() async throws {
        let dataPoints = createTestDataPoints(count: 1)

        let fileURL = try await exportService.exportToCSV(dataPoints: dataPoints)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines[0], "timestamp,x,y,z")

        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportToCSV_HasCorrectNumberOfRows() async throws {
        let dataPoints = createTestDataPoints(count: 5)

        let fileURL = try await exportService.exportToCSV(dataPoints: dataPoints)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 6)

        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportToCSV_FormatsNumbersCorrectly() async throws {
        let dataPoint = MotionDataPoint(
            timestamp: 123.456,
            x: 0.123456789,
            y: -0.987654321,
            z: 0.5
        )

        let fileURL = try await exportService.exportToCSV(dataPoints: [dataPoint])
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")
        let dataLine = lines[1]
        let components = dataLine.components(separatedBy: ",")

        XCTAssertEqual(components.count, 4)
        XCTAssertEqual(components[0], "123.456")
        XCTAssertEqual(components[1], "0.123457")
        XCTAssertEqual(components[2], "-0.987654")
        XCTAssertEqual(components[3], "0.500000")

        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportToCSV_WithEmptyArray_CreatesFileWithHeaderOnly() async throws {
        let dataPoints: [MotionDataPoint] = []

        let fileURL = try await exportService.exportToCSV(dataPoints: dataPoints)
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0], "timestamp,x,y,z")

        try? FileManager.default.removeItem(at: fileURL)
    }

    func testExportToCSV_GeneratesUniqueFilenames() async throws {
        let dataPoints = createTestDataPoints(count: 1)

        let url1 = try await exportService.exportToCSV(dataPoints: dataPoints)

        try await Task.sleep(nanoseconds: 1_100_000_000)

        let url2 = try await exportService.exportToCSV(dataPoints: dataPoints)

        XCTAssertNotEqual(url1.lastPathComponent, url2.lastPathComponent)

        try? FileManager.default.removeItem(at: url1)
        try? FileManager.default.removeItem(at: url2)
    }

    private func createTestDataPoints(count: Int) -> [MotionDataPoint] {
        (0..<count).map { index in
            MotionDataPoint(
                timestamp: Double(index + 1),
                x: Double.random(in: -1...1),
                y: Double.random(in: -1...1),
                z: Double.random(in: -1...1)
            )
        }
    }
}
