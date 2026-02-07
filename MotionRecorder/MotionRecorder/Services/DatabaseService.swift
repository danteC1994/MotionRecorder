import Foundation
import GRDB

final class DatabaseService: DatabaseServiceProtocol {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    convenience init() throws {
        let fileManager = FileManager.default
        let documentsPath = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbPath = documentsPath.appendingPathComponent(Constants.databaseFileName).path
        let dbQueue = try DatabaseQueue(path: dbPath)
        self.init(dbQueue: dbQueue)
    }

    func initialize() throws {
        try dbQueue.write { db in
            try db.create(table: "motion_data", ifNotExists: true) { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("timestamp", .real).notNull()
                table.column("x", .real).notNull()
                table.column("y", .real).notNull()
                table.column("z", .real).notNull()
            }

            try db.create(index: "idx_timestamp", on: "motion_data", columns: ["timestamp"], ifNotExists: true)
        }
    }

    func insert(_ dataPoint: MotionDataPoint) async throws {
        try await dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO motion_data (timestamp, x, y, z) VALUES (?, ?, ?, ?)",
                arguments: [dataPoint.timestamp, dataPoint.x, dataPoint.y, dataPoint.z]
            )
        }
    }

    func insertBatch(_ dataPoints: [MotionDataPoint]) async throws {
        guard !dataPoints.isEmpty else { return }

        try await dbQueue.write { db in
            for dataPoint in dataPoints {
                try db.execute(
                    sql: "INSERT INTO motion_data (timestamp, x, y, z) VALUES (?, ?, ?, ?)",
                    arguments: [dataPoint.timestamp, dataPoint.x, dataPoint.y, dataPoint.z]
                )
            }
        }
    }

    func fetchDataSince(_ timestamp: TimeInterval) async throws -> [MotionDataPoint] {
        try await dbQueue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: "SELECT id, timestamp, x, y, z FROM motion_data WHERE timestamp > ? ORDER BY timestamp ASC",
                arguments: [timestamp]
            )

            return rows.map { row in
                MotionDataPoint(
                    id: row["id"],
                    timestamp: row["timestamp"],
                    x: row["x"],
                    y: row["y"],
                    z: row["z"]
                )
            }
        }
    }

    func getFirstRecordingTime() async throws -> Date? {
        try await dbQueue.read { db in
            if let timestamp = try Double.fetchOne(
                db,
                sql: "SELECT MIN(timestamp) FROM motion_data"
            ) {
                return Date(timeIntervalSinceReferenceDate: timestamp)
            }
            return nil
        }
    }

    func getLastRecordingTime() async throws -> Date? {
        try await dbQueue.read { db in
            if let timestamp = try Double.fetchOne(
                db,
                sql: "SELECT MAX(timestamp) FROM motion_data"
            ) {
                return Date(timeIntervalSinceReferenceDate: timestamp)
            }
            return nil
        }
    }

    func getRecordCount() async throws -> Int {
        try await dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM motion_data") ?? 0
        }
    }
}
