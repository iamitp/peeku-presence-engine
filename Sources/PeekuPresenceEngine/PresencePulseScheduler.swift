import Foundation

public struct PresencePulsePlan: Sendable, Equatable {
    public enum Reason: Sendable, Equatable {
        case waiting
        case stablePresence
        case activeAbsence
        case eyeRestConfirmation
        case enrolment
    }

    public var shouldEvaluateFrame: Bool
    public var reason: Reason
    public var visionWorkload: VisionWorkload
    public var samplesBrightness: Bool

    public init(
        shouldEvaluateFrame: Bool,
        reason: Reason,
        visionWorkload: VisionWorkload,
        samplesBrightness: Bool
    ) {
        self.shouldEvaluateFrame = shouldEvaluateFrame
        self.reason = reason
        self.visionWorkload = visionWorkload
        self.samplesBrightness = samplesBrightness
    }
}

public struct VisionWorkload: Sendable, Equatable {
    public var usesLandmarks: Bool
    public var usesBodyPose: Bool

    public init(usesLandmarks: Bool, usesBodyPose: Bool) {
        self.usesLandmarks = usesLandmarks
        self.usesBodyPose = usesBodyPose
    }

    public static let rectanglesOnly = VisionWorkload(usesLandmarks: false, usesBodyPose: false)
}

public struct PresenceFrameObservation: Sendable, Equatable {
    public var facesDetected: Int
    public var eyeRestObserved: Bool

    public init(facesDetected: Int, eyeRestObserved: Bool) {
        self.facesDetected = facesDetected
        self.eyeRestObserved = eyeRestObserved
    }
}

public struct PresencePulseScheduler: Sendable, Equatable {
    public var cadence: PresencePulseCadence

    private var lastFrameEvaluationAt: Date
    private var lastLandmarkEvaluationAt: Date
    private var lastBrightnessSampleAt: Date
    private var lastBodyPoseAssistAt: Date

    public init(
        cadence: PresencePulseCadence = .peekuJuly2026,
        seedDate: Date = .distantPast
    ) {
        self.cadence = cadence
        lastFrameEvaluationAt = seedDate
        lastLandmarkEvaluationAt = seedDate
        lastBrightnessSampleAt = seedDate
        lastBodyPoseAssistAt = seedDate
    }

    public mutating func planCapture(
        at now: Date,
        context: PresencePulseContext
    ) -> PresencePulsePlan {
        let reason = pulseReason(for: context)
        let interval = interval(for: reason)
        guard now.timeIntervalSince(lastFrameEvaluationAt) >= interval else {
            return PresencePulsePlan(
                shouldEvaluateFrame: false,
                reason: .waiting,
                visionWorkload: .rectanglesOnly,
                samplesBrightness: false
            )
        }

        lastFrameEvaluationAt = now
        let workload = visionWorkload(at: now, context: context)
        let samplesBrightness = shouldSampleBrightness(at: now)

        return PresencePulsePlan(
            shouldEvaluateFrame: true,
            reason: reason,
            visionWorkload: workload,
            samplesBrightness: samplesBrightness
        )
    }

    public func pauseDelay(
        after observation: PresenceFrameObservation,
        context: PresencePulseContext
    ) -> TimeInterval {
        if observation.facesDetected > 0, context.eyeRestDue, !context.walkPromptDue {
            return cadence.eyeRestConfirmationInterval
        }
        if observation.facesDetected > 0 {
            return cadence.stablePresenceInterval
        }
        return cadence.activeAbsenceInterval
    }

    private func pulseReason(for context: PresencePulseContext) -> PresencePulsePlan.Reason {
        if context.phase == .enrolling {
            return .enrolment
        }
        if !context.facePresent || context.missingFaceSamples > 0 {
            return .activeAbsence
        }
        if context.eyeRestDue && !context.walkPromptDue {
            return .eyeRestConfirmation
        }
        return .stablePresence
    }

    private func interval(for reason: PresencePulsePlan.Reason) -> TimeInterval {
        switch reason {
        case .waiting:
            return .infinity
        case .stablePresence:
            return cadence.stablePresenceInterval
        case .activeAbsence:
            return cadence.activeAbsenceInterval
        case .eyeRestConfirmation:
            return cadence.eyeRestConfirmationInterval
        case .enrolment:
            return cadence.enrolmentInterval
        }
    }

    private mutating func visionWorkload(
        at now: Date,
        context: PresencePulseContext
    ) -> VisionWorkload {
        let landmarks = shouldRunLandmarks(at: now)
        let bodyPose = shouldRunBodyPose(at: now, context: context)
        return VisionWorkload(usesLandmarks: landmarks, usesBodyPose: bodyPose)
    }

    private mutating func shouldRunLandmarks(at now: Date) -> Bool {
        guard now.timeIntervalSince(lastLandmarkEvaluationAt) >= cadence.landmarkInterval else {
            return false
        }
        lastLandmarkEvaluationAt = now
        return true
    }

    private mutating func shouldSampleBrightness(at now: Date) -> Bool {
        guard now.timeIntervalSince(lastBrightnessSampleAt) >= cadence.brightnessSampleInterval else {
            return false
        }
        lastBrightnessSampleAt = now
        return true
    }

    private mutating func shouldRunBodyPose(
        at now: Date,
        context: PresencePulseContext
    ) -> Bool {
        if context.bodyPoseHintsEnabled {
            return true
        }
        guard context.bodyPoseLockAssistEnabled else {
            return false
        }
        guard !context.facePresent || context.missingFaceSamples > 0 else {
            return false
        }
        guard now.timeIntervalSince(context.lastFaceSeen) >= cadence.bodyPoseAssistWarmup else {
            return false
        }
        guard now.timeIntervalSince(lastBodyPoseAssistAt) >= cadence.bodyPoseAssistInterval else {
            return false
        }
        lastBodyPoseAssistAt = now
        return true
    }
}
