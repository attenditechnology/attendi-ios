# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0 - 2025-08-08]

### Added
- AudioRecorder and AudioRecorderImpl: Wrap the lower-level AVAudioEngine and AVAudioSession APIs to provide a convenient, asynchronous protocol for capturing audio from the device, ensuring Swift Concurrency support and streamlined usage.
- AttendiRecorder and AttendiRecorderImpl: High-level recording interfaces that manage audio capture, plugin coordination, and lifecycle events without requiring direct UI interaction.
- AsyncTranscribeService: Enables integration with real-time or streaming transcription services through a Swift Concurrency–friendly interface.
- New plugin system for recorders: Introduced AttendiRecorderPlugin, decoupled from AttendiMicrophonePlugin, allowing more granular control over recording behavior.
- New plugins:
  * AttendiAsyncTranscribePlugin: Supports real-time transcription by integrating with AsyncTranscribeService.
  * AttendiStopOnAudioInterruptionPlugin: Adds graceful handling of system audio interruptions to prevent conflicts with other apps (e.g., incoming call).

### Changed
- Refactored SDK architecture: Major reorganization to improve separation of concerns and encapsulation:
  * Clear distinctions between AudioRecorder, AttendiRecorder, and AttendiMicrophone layers.
  * Organized internal boundaries and modular file structure for improved maintainability.
- AttendiTranscribePlugin now supports injecting a TranscribeService and AudioEncoder for improved extensibility, supporting alternative implementations beyond the default Attendi transcription service.
- Increased SDK Min Deployment iOS version to iOS 15.

### Improved
- Project structure modernization: The SDK is now packaged as a dynamic framework, allowing build-time script execution (e.g., SwiftGen) for generating type-safe access to resources such as localized strings, assets, and more. This improves compile-time safety and developer productivity when working within the SDK.
- Thread safety and lifecycle handling:
  * Enhanced lifecycle-aware resource cleanup using structured concurrency.
  * Improved stability and reliability of audio operations in AudioRecorder and AttendiRecorder, preventing memory leaks and avoiding illegal state transitions.
- New recording examples: The SDK example now covers and validate all core SDK functionalities, including audio recording, live transcription, plugin integration, and error handling.

### Breaking Changes

- Class renaming:
MicrophoneUIState → AttendiRecorderState
TranscribeAPIConfig → AttendiTranscribeAPIConfig

- AttendiTranscribeAPIConfig updated fields:
```swift
// Old:
let apiURL: String
let modelType: ModelType

// New:
let apiBaseURL: String
let modelType: String? = null
```

- AttendiMicrophone parameters moved into settings:
```swift
// Old:
AttendiMicrophone(
    size: 64,
    colors: AttendiMicrophone.Colors(baseColor: Color.red)
)

// New:
AttendiMicrophone(
    settings = AttendiMicrophoneSettings(
        size: 64,
        colors: AttendiMicrophoneDefaults.colors(baseColor: Color.red)
    )
)
```

- Plugin system migration from AttendiMicrophone to AttendiRecorder:
```swift
// Old:
AttendiMicrophone(
    plugins = [
        AttendiErrorPlugin(),
        AttendiTranscribePlugin(apiConfig = exampleAPIConfig)
    ]
) { newText: String in
  // ...
)

// New:
private let recorder = AttendiRecorderFactory.create()

AttendiMicrophone(recorder: recorder)
.onAppear {
  Task {
    await recorder.setPlugins(
      AttendiErrorPlugin(),
      AttendiSyncTranscribePlugin(
        service: AttendiTranscribeServiceFactory.create(
          apiConfig: apiConfig
        ),
        onTranscribeCompleted: { transcript: String?, error: Error? in
          // .. 
    )
  }
}
```

## [0.2.2 - 2023-11-29]

### Fixed

- memory leak of AttendiTranscribePlugin

  Since `AttendiMicrophone` is a struct containing reference types like
  Callbacks, using it in closures can create strong references to those
  reference types that create retain cycles and are therefore not garbage collected,
  creating memory leaks. Currently, we move all the references to the mic in the plugin
  outside of any closure definitions, which seems to fix the issue. In terms of dev
  experience, it's not really nice, since you have to define all the methods above the
  closures before using them.

## [0.2.1 - 2023-11-23]

### Added

- Add `onDisappear` plugin API

  When using the microphone in a UIHostingController, somehow it is possible
  for the view's `onDisappear` and `onAppear` functions to be called again (after the first time!)
  when the application is backgrounded and foregrounded again, even when the rest
  of the state of the view persists.
  The newly added `onDisappear` function allows clients to stop the recording when the view disappears.

  An example:

  ```swift
  /// An example plugin that handles a case in which the app is backgrounded while the mic is recording.
  /// Currently stops the recording and performs any registered audio tasks when the view disappears.
  ///
  /// When using the microphone in a UIHostingController, somehow it is possible
  /// for the view's `onDisappear` and `onAppear` functions to be called again (after the first time!)
  /// when the application is backgrounded and foregrounded again, even when the rest
  /// of the state of the view persists.

  public class AttendiHandleBackgroundingPlugin: AttendiMicrophonePlugin {
      var clearCallbacks: [() -> Void] = []

      public override func activate(_ mic: AttendiMicrophone) {
          Task {
              clearCallbacks.append(
                  mic.callbacks.onDisappear {
                      // Stop recording and call the registered audio tasks when `onDisappear`
                      // is called.
                      if (mic.recorder.state == .recording) {
                          await mic.stop(delayMilliseconds: 0)
                      }
                  }
              )
          }
      }

      public override func deactivate(_ mic: AttendiMicrophone) {
          for callback in clearCallbacks {
              callback()
          }

          clearCallbacks = []
      }
  }
  ```

### Fixed

- Implemented `deactivate` method for default plugins `AudioNotificationPlugin` and `VolumeFeedbackPlugin` and for the plugin `AttendiErrorPlugin`.

  These were not implemented as it was previously assumed that onDisappear and onAppear would not
  be called when backgrounding and foregrounding respectively. The plugins are activated and deactivated
  in these methods. Since the deactivate method was not implemented for some plugins, callbacks would be
  registered multiple times without cleaning up in between. Now, we make sure to properly implement the
  deactivate function for the plugins included in the microphone by default.

- Tooltip flashing in and out

  In the tooltip presentation logic, we now only present the popover if it doesn't already
  exist.
  Previously the we would dismiss and re-present
  the popover if it already exists. However, this leads to the popover to
  flash in and out when the SwiftUI view re-renders. The current behavior
  seems to better match what is intended.

## [0.2.0] - 2023-11-17

### Modified

- Change notification sound behavior:

  The way the notification sounds were playing, they were audible in the
  recorded audio. This sometimes lead to the transcription models
  erroneously adding a spurious 'o' at the beginning of the transcript.

  To prevent this:

  - We only start recording after the start notification is done playing.
    We shorten the delay before showing the recording UI by the amount of time
    playing the audio takes.
  - We play the stop notification after recording is stopped (and shorten
    the stopping delay so the delay doesn't feel too laggy).

### Fixed

- Error text not showing in tooltip when microphone permission is denied.
- Resume recording on foregrounding if necessary.

  When using the microphone in a `UIHostingController`, somehow it is possible for `onDisappear` and `onAppear` to be called again (after the first time!) when the application is backgrounded and foregrounded again, even when the rest of the state of the view persists. Since we stop the recorder in the `onDisappear` to clean up after ourselves, it is possible that we are only backgrounding the app and therefore need to continue recording when the app is foregrounded again. We make sure to automatically continue recording now when the app is foregrounded again.

- Very occasionally the application process crashes when starting recording. We're not completely sure yet what causes this, but we make the startRecording function a little bit more defensive by:
  - throwing if either `session.setCategory` or `session.setActive` fails
  - throwing if the channel count is 0
  - resetting the audio engine before installing the tap
  - removing any taps on the same bus that we will install the tap on
    Though we're not sure yet if one of these things caused the issue, we will find out.

### Removed

- Removed the `AttendiMicrophone.onVolume` plugin API. Instead, use `AttendiMicrophone.recorder.onSignalEnergy` to access the recorded audio's signal energy / volume.

## [0.1.0] - 2023-10-16

First release of the package.
