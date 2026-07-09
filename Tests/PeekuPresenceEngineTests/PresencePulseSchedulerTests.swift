import XCTest
@testable import PeekuPresenceEngine

final class PresencePulseSchedulerTests: XCTestCase {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    func testStablePresenceUsesTenSecondCadence() {
        var scheduler = PresencePulseScheduler(seedDate: base)
        let context = PresencePulseContext(
            phase: .monitoring,
            facePresent: true,
            missingFaceSamples: 0,
            eyeRestDue: false,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )

        XCTAssertFalse(scheduler.planCapture(at: base.addingTimeInterval(9.9), context: context).shouldEvaluateFrame)
        let plan = scheduler.planCapture(at: base.addingTimeInterval(10.0), context: context)
        XCTAssertTrue(plan.shouldEvaluateFrame)
        XCTAssertEqual(plan.reason, .stablePresence)
    }

    func testActiveAbsenceUsesFiveSecondCadence() {
        var scheduler = PresencePulseScheduler(seedDate: base)
        let context = PresencePulseContext(
            phase: .monitoring,
            facePresent: false,
            missingFaceSamples: 1,
            eyeRestDue: false,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )

        XCTAssertFalse(scheduler.planCapture(at: base.addingTimeInterval(4.9), context: context).shouldEvaluateFrame)
        let plan = scheduler.planCapture(at: base.addingTimeInterval(5.0), context: context)
        XCTAssertTrue(plan.shouldEvaluateFrame)
        XCTAssertEqual(plan.reason, .activeAbsence)
    }

    func testEyeRestDueUsesTwoSecondConfirmationCadenceUnlessWalkPromptIsDue() {
        var scheduler = PresencePulseScheduler(seedDate: base)
        let eyeContext = PresencePulseContext(
            phase: .monitoring,
            facePresent: true,
            missingFaceSamples: 0,
            eyeRestDue: true,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )
        let walkContext = PresencePulseContext(
            phase: .monitoring,
            facePresent: true,
            missingFaceSamples: 0,
            eyeRestDue: true,
            walkPromptDue: true,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )

        XCTAssertTrue(scheduler.planCapture(at: base.addingTimeInterval(2.0), context: eyeContext).shouldEvaluateFrame)

        scheduler = PresencePulseScheduler(seedDate: base)
        XCTAssertFalse(scheduler.planCapture(at: base.addingTimeInterval(2.0), context: walkContext).shouldEvaluateFrame)
        XCTAssertTrue(scheduler.planCapture(at: base.addingTimeInterval(10.0), context: walkContext).shouldEvaluateFrame)
    }

    func testEnrolmentUsesQuarterSecondCadence() {
        var scheduler = PresencePulseScheduler(seedDate: base)
        let context = PresencePulseContext(
            phase: .enrolling,
            facePresent: true,
            missingFaceSamples: 0,
            eyeRestDue: false,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )

        XCTAssertFalse(scheduler.planCapture(at: base.addingTimeInterval(0.24), context: context).shouldEvaluateFrame)
        XCTAssertTrue(scheduler.planCapture(at: base.addingTimeInterval(0.25), context: context).shouldEvaluateFrame)
    }

    func testLandmarksAndBrightnessAreThrottledSeparately() {
        var scheduler = PresencePulseScheduler(seedDate: base)
        let context = PresencePulseContext(
            phase: .monitoring,
            facePresent: false,
            missingFaceSamples: 1,
            eyeRestDue: false,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )

        let first = scheduler.planCapture(at: base.addingTimeInterval(5.0), context: context)
        XCTAssertTrue(first.visionWorkload.usesLandmarks)
        XCTAssertTrue(first.samplesBrightness)

        let second = scheduler.planCapture(at: base.addingTimeInterval(10.0), context: context)
        XCTAssertTrue(second.visionWorkload.usesLandmarks)
        XCTAssertTrue(second.samplesBrightness)
    }

    func testBodyPoseAssistWaitsForAbsenceWarmupAndInterval() {
        var scheduler = PresencePulseScheduler(seedDate: base)
        let beforeWarmup = PresencePulseContext(
            phase: .monitoring,
            facePresent: false,
            missingFaceSamples: 1,
            eyeRestDue: false,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: true,
            lastFaceSeen: base.addingTimeInterval(4.0)
        )
        let afterWarmup = PresencePulseContext(
            phase: .monitoring,
            facePresent: false,
            missingFaceSamples: 1,
            eyeRestDue: false,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: true,
            lastFaceSeen: base
        )

        XCTAssertFalse(scheduler.planCapture(at: base.addingTimeInterval(5.0), context: beforeWarmup).visionWorkload.usesBodyPose)

        scheduler = PresencePulseScheduler(seedDate: base)
        XCTAssertTrue(scheduler.planCapture(at: base.addingTimeInterval(5.0), context: afterWarmup).visionWorkload.usesBodyPose)
        XCTAssertFalse(scheduler.planCapture(at: base.addingTimeInterval(7.0), context: afterWarmup).visionWorkload.usesBodyPose)
        XCTAssertTrue(scheduler.planCapture(at: base.addingTimeInterval(10.0), context: afterWarmup).visionWorkload.usesBodyPose)
    }

    func testPauseDelayFollowsObservation() {
        let scheduler = PresencePulseScheduler()
        let context = PresencePulseContext(
            phase: .monitoring,
            facePresent: true,
            missingFaceSamples: 0,
            eyeRestDue: true,
            walkPromptDue: false,
            bodyPoseHintsEnabled: false,
            bodyPoseLockAssistEnabled: false,
            lastFaceSeen: base
        )

        XCTAssertEqual(
            scheduler.pauseDelay(after: PresenceFrameObservation(facesDetected: 1, eyeRestObserved: false), context: context),
            2.0
        )
        XCTAssertEqual(
            scheduler.pauseDelay(after: PresenceFrameObservation(facesDetected: 0, eyeRestObserved: false), context: context),
            5.0
        )
    }
}
