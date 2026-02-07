import Foundation

protocol MotionServiceProtocol: Sendable {
    var isRecording: Bool { get }
    func startRecording(handler: @escaping @Sendable (MotionDataPoint) -> Void)
    func stopRecording()
    func isAccelerometerAvailable() -> Bool
}
