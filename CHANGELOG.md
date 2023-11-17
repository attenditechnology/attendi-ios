# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
