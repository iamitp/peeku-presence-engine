import Foundation
import PeekuPresenceEngine

// Each row is an independent sample supplied by the example.
let samples = [
    (label: "At the desk", faces: 1, eyeRestDue: false),
    (label: "No face in the sample", faces: 0, eyeRestDue: false),
    (label: "Eye rest due", faces: 1, eyeRestDue: true),
]

let scheduler = PresencePulseScheduler()
for sample in samples {
    let context = PresencePulseContext(
        phase: .monitoring,
        facePresent: sample.faces > 0,
        missingFaceSamples: sample.faces == 0 ? 1 : 0,
        eyeRestDue: sample.eyeRestDue,
        walkPromptDue: false,
        bodyPoseHintsEnabled: false,
        bodyPoseLockAssistEnabled: false,
        lastFaceSeen: .distantPast
    )
    let frame = PresenceFrameObservation(facesDetected: sample.faces, eyeRestObserved: false)
    let seconds = scheduler.pauseDelay(after: frame, context: context)
    print("\(sample.label): next camera check in \(seconds.formatted()) s")
}
