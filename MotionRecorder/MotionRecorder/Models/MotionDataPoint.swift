import Foundation

struct MotionDataPoint: Codable, Equatable, Identifiable {
    var id: Int64?
    let timestamp: TimeInterval
    let x: Double
    let y: Double
    let z: Double

    init(id: Int64? = nil, timestamp: TimeInterval, x: Double, y: Double, z: Double) {
        self.id = id
        self.timestamp = timestamp
        self.x = x
        self.y = y
        self.z = z
    }
}

extension MotionDataPoint {
    var date: Date {
        Date(timeIntervalSinceReferenceDate: timestamp)
    }
}
