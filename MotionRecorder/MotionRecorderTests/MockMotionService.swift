import Foundation
@testable import MotionRecorder

final class MockMotionService: MotionServiceProtocol {
    var isRecording: Bool = false
    var isAvailable: Bool = true
    var recordingHandler: (@Sendable (MotionDataPoint) -> Void)?
    var startRecordingCalled = false
    var stopRecordingCalled = false

    func isAccelerometerAvailable() -> Bool {
        isAvailable
    }

    func startRecording(handler: @escaping @Sendable (MotionDataPoint) -> Void) {
        startRecordingCalled = true
        isRecording = true
        recordingHandler = handler
    }

    func stopRecording() {
        stopRecordingCalled = true
        isRecording = false
        recordingHandler = nil
    }

    func simulateMotionData(_ dataPoint: MotionDataPoint) {
        recordingHandler?(dataPoint)
    }
}
