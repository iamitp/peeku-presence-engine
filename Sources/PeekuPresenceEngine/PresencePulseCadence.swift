import Foundation

public struct PresencePulseCadence: Sendable, Equatable {
    public var stablePresenceInterval: TimeInterval
    public var activeAbsenceInterval: TimeInterval
    public var eyeRestConfirmationInterval: TimeInterval
    public var enrolmentInterval: TimeInterval
    public var landmarkInterval: TimeInterval
    public var brightnessSampleInterval: TimeInterval
    public var bodyPoseAssistWarmup: TimeInterval
    public var bodyPoseAssistInterval: TimeInterval

    public init(
        stablePresenceInterval: TimeInterval,
        activeAbsenceInterval: TimeInterval,
        eyeRestConfirmationInterval: TimeInterval,
        enrolmentInterval: TimeInterval,
        landmarkInterval: TimeInterval,
        brightnessSampleInterval: TimeInterval,
        bodyPoseAssistWarmup: TimeInterval,
        bodyPoseAssistInterval: TimeInterval
    ) {
        self.stablePresenceInterval = stablePresenceInterval
        self.activeAbsenceInterval = activeAbsenceInterval
        self.eyeRestConfirmationInterval = eyeRestConfirmationInterval
        self.enrolmentInterval = enrolmentInterval
        self.landmarkInterval = landmarkInterval
        self.brightnessSampleInterval = brightnessSampleInterval
        self.bodyPoseAssistWarmup = bodyPoseAssistWarmup
        self.bodyPoseAssistInterval = bodyPoseAssistInterval
    }

    public static let peekuJuly2026 = PresencePulseCadence(
        stablePresenceInterval: 10.0,
        activeAbsenceInterval: 5.0,
        eyeRestConfirmationInterval: 2.0,
        enrolmentInterval: 0.25,
        landmarkInterval: 5.0,
        brightnessSampleInterval: 2.0,
        bodyPoseAssistWarmup: 2.0,
        bodyPoseAssistInterval: 3.0
    )
}
