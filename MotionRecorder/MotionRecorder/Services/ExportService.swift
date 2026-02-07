import Foundation

final class ExportService: ExportServiceProtocol {

    func exportToCSV(dataPoints: [MotionDataPoint]) async throws -> URL {
        let fileName = generateFileName()
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csvContent = Constants.csvHeader + "\n"

        for dataPoint in dataPoints {
            let row = formatCSVRow(dataPoint)
            csvContent.append(row + "\n")
        }

        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }

    private func generateFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.csvFileDateFormat
        let dateString = dateFormatter.string(from: Date())
        return "\(Constants.csvFileNamePrefix)_\(dateString).csv"
    }

    private func formatCSVRow(_ dataPoint: MotionDataPoint) -> String {
        let timestamp = String(format: "%.3f", dataPoint.timestamp)
        let x = String(format: "%.6f", dataPoint.x)
        let y = String(format: "%.6f", dataPoint.y)
        let z = String(format: "%.6f", dataPoint.z)

        return "\(timestamp),\(x),\(y),\(z)"
    }
}
