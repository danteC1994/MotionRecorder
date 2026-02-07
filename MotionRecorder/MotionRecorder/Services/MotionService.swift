import Foundation
import CoreMotion

final class MotionService: MotionServiceProtocol, @unchecked Sendable {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    private var dataHandler: (@Sendable (MotionDataPoint) -> Void)?

    private(set) var isRecording: Bool = false

    init() {
        operationQueue.name = "com.motionrecorder.motion"
        operationQueue.qualityOfService = .userInitiated
    }

    deinit {
        stopRecording()
    }

    func isAccelerometerAvailable() -> Bool {
        motionManager.isAccelerometerAvailable
    }

    func startRecording(handler: @escaping @Sendable (MotionDataPoint) -> Void) {
        guard !isRecording else { return }
        guard motionManager.isAccelerometerAvailable else { return }

        self.dataHandler = handler
        motionManager.accelerometerUpdateInterval = Constants.motionUpdateInterval

        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, error in
            guard let self = self, self.isRecording else { return }
            guard error == nil, let data = data else { return }

            let dataPoint = MotionDataPoint(
                timestamp: data.timestamp,
                x: data.acceleration.x,
                y: data.acceleration.y,
                z: data.acceleration.z
            )

            self.dataHandler?(dataPoint)
        }

        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }

        motionManager.stopAccelerometerUpdates()
        isRecording = false
        dataHandler = nil
    }
}
