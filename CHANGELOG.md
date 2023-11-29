# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
