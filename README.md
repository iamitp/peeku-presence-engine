# Peeku Presence Engine

Peeku Presence Engine is the small Swift scheduling core behind Peeku's low-CPU
presence loop. It does not ship camera, Vision, face identity, locking, UI, or
analytics code. It only decides when a presence app should wake the camera,
which vision workload to run, and how long the camera can sleep after a sample.

The package is extracted from the July 2026 Peeku pulsed-capture rewrite, where
the Mac camera path moved from a continuously running video session to short
capture pulses:

- stable face-present desk state: sample around every 10s
- active absence or missing-face state: sample around every 5s
- eye-rest confirmation while a break is due: sample around every 2s
- enrolment: sample continuously enough for UX, around every 0.25s
- landmarks, brightness, and body-pose assist are throttled separately

On Amit's iMac, the original always-on camera path measured around 33-51% CPU.
The failed metadata-face attempt averaged 28.9% over 19 samples. The pulsed
video build averaged 7.0% over 19 samples across 3+ minutes, with short camera
spikes and 1-2% between pulses.

## Run the example

With Swift 5.10 or later on macOS, run these commands in Terminal:

```sh
git clone https://github.com/iamitp/peeku-presence-engine.git
cd peeku-presence-engine
swift run pulse-demo
```

The [example](Examples/PulseDemo/main.swift) passes three sample observations to the scheduler. It runs without camera access. With Peeku’s default timings it prints:

```text
At the desk: next camera check in 10 s
No face in the sample: next camera check in 5 s
Eye rest due: next camera check in 2 s
```

If you run the example on your Mac, [tell us whether it worked](https://github.com/iamitp/peeku-presence-engine/issues/new?title=Running%20the%20pulse%20example). Your Swift version and the output are enough.

To try the Mac app, visit [Peeku on GitHub](https://github.com/iamitp/peeku-releases).

## Install

```swift
.package(url: "https://github.com/iamitp/peeku-presence-engine.git", from: "0.1.0")
```

## Use

```swift
import PeekuPresenceEngine

var scheduler = PresencePulseScheduler(cadence: .peekuJuly2026)

let plan = scheduler.planCapture(
    at: Date(),
    context: PresencePulseContext(
        phase: .monitoring,
        facePresent: true,
        missingFaceSamples: 0,
        eyeRestDue: false,
        walkPromptDue: false,
        bodyPoseHintsEnabled: false,
        bodyPoseLockAssistEnabled: true,
        lastFaceSeen: Date()
    )
)

if plan.shouldEvaluateFrame {
    // Start or keep a capture session alive for one evaluated frame.
    // Run face rectangles or landmarks based on plan.visionWorkload.
}
```

After evaluating a frame, ask how long the camera can sleep:

```swift
let pause = scheduler.pauseDelay(
    after: PresenceFrameObservation(
        facesDetected: 1,
        eyeRestObserved: false
    ),
    context: context
)
```

The package is deliberately small. It is meant to make the cadence auditable and
testable, while your app remains responsible for AVFoundation setup, Vision
requests, privacy copy, permission prompts, and lock or notification behaviour.

## License

MIT.
