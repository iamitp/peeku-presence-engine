import Foundation

public struct PresencePulseContext: Sendable, Equatable {
    public enum Phase: Sendable, Equatable {
        case monitoring
        case enrolling
    }

    public var phase: Phase
    public var facePresent: Bool
    public var missingFaceSamples: Int
    public var eyeRestDue: Bool
    public var walkPromptDue: Bool
    public var bodyPoseHintsEnabled: Bool
    public var bodyPoseLockAssistEnabled: Bool
    public var lastFaceSeen: Date

    public init(
        phase: Phase,
        facePresent: Bool,
        missingFaceSamples: Int,
        eyeRestDue: Bool,
        walkPromptDue: Bool,
        bodyPoseHintsEnabled: Bool,
        bodyPoseLockAssistEnabled: Bool,
        lastFaceSeen: Date
    ) {
        self.phase = phase
        self.facePresent = facePresent
        self.missingFaceSamples = missingFaceSamples
        self.eyeRestDue = eyeRestDue
        self.walkPromptDue = walkPromptDue
        self.bodyPoseHintsEnabled = bodyPoseHintsEnabled
        self.bodyPoseLockAssistEnabled = bodyPoseLockAssistEnabled
        self.lastFaceSeen = lastFaceSeen
    }
}
