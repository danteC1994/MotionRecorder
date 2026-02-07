import Foundation

enum Constants {
    static let samplingFrequency: Double = 50.0
    static let motionUpdateInterval: TimeInterval = 1.0 / samplingFrequency
    static let batchInsertSize: Int = Int(samplingFrequency)

    static let databaseFileName = "motion_data.sqlite"

    enum UserDefaultsKeys {
        static let lastExportTime = "lastExportTime"
        static let firstRecordingTime = "firstRecordingTime"
        static let lastRecordingTime = "lastRecordingTime"
    }

    static let csvFileNamePrefix = "motion_data_export"
    static let csvFileDateFormat = "yyyyMMdd_HHmmss"
    static let csvHeader = "timestamp,x,y,z"
}
