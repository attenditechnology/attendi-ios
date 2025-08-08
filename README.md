# Attendi Speech Service for iOS

The Attendi Speech Service iOS SDK provides tools for capturing and processing audio in Android applications. It includes `AttendiMicrophone`, a customizable SwiftUI component, and `AttendiRecorder`, an asynchronous protocol for low-level audio recording built with Swift Concurrency.

The SDK is designed with extensibility in mind, supporting plugins to customize behavior like transcription, feedback, and error handling.

## Getting started

The SDK is available as a dynamic framework that can be integrated using either Swift Package Manager or Carthage.

### Installation instructions

* There are three ways to install the SDK using Swift Package Manager:

_Option 1: Local Installation (For Development)_
- Clone the Repository
git clone https://github.com/attenditechnology/attendi-ios.git
- Add Local Swift Package
In Xcode:
- Open your app's .xcodeproj file (e.g., AttendiSpeechServiceExample.xcodeproj).
- Select the project in the Project Navigator.
- Go to the Package Dependencies tab.
- Click the "+" button.
- Choose "Add Local...".
- Select the cloned repository folder (where Package.swift is located).
- Finish the setup and confirm.

_Option 2: Remote URL Installation (Recommended for Consumers)_
- Open your project in Xcode.
- Go to the Package Dependencies tab in the project settings.
- Click the "+" button to add a new package.
- Enter the following GitHub URL:
https://github.com/attenditechnology/attendi-ios
- Select the main branch or a specific version.
- Click Add Package.

_Option 3: Add via Package.swift (For SwiftPM Projects)_
- Add the following to your Package.swift dependencies:
dependencies: [
    .package(url: "https://github.com/attenditechnology/attendi-ios", from: "0.3.0")
]
- Then run:
swift package resolve

Once the package is added using any of the options above, link it to your app target:
- Select your app target in the project settings.
- Go to the General tab.
- Scroll down to Frameworks, Libraries, and Embedded Content.
- Make sure AttendiSpeechService is listed.
- If it’s not, click the "+", search for AttendiSpeechService, and add it.

* To fetch the Attendi Speech Service as a Carthage framework:
1. Add the dependency to your Cartfile:
github attenditechnology/attendi-ios
2. Run carthage:
carthage update --use-xcframeworks
3. In Xcode:
- Select your app target.
- Go to the General tab.
- Scroll down to Frameworks, Libraries, and Embedded Content.
- Click the "+", find AttendiSpeechService.xcframework, and add it.
- If you are adding the framework to an "App target", ensure it is set to "Embed & Sign", otherwise
if you are embedding the framework into another framework, ensure it is set to "Do Not Embed".

## Usage

After installation and linking, you can use the microphone component and/or the recorder component in your project:

```swift
import AttendiSpeechService
```

## Core Components

### AttendiRecorder

An async protocol for recording audio using Apple’s AVAudioEngine or AVAudioRecorder APIs. It supports:
* Async start/stop recording (with optional delays)
* ObservableObject-based state observation (@Published)
* Resource management
* Plugin-driven behavior via AttendiRecorderPlugin

Example Usage
```swift
let recorder = AttendiRecorderFactory.create()

private func onButtonPressed() {
    Task {
        if recorder.model.state == AttendiRecorderState.notStartedRecording {
            await recorder.start()
        } else if recorder.model.state == AttendiRecorderState.recording {
            await recorder.stop()
        }
    }
}
```

### AttendiMicrophone
A SwiftUI component designed for audio capture using a visual microphone button. It integrates with an AttendiRecorder instance and supports plugin-driven behavior, visual feedback, and customization of appearance and interaction.

Example Usage
```swift
AttendiMicrophone(
    recorder: recorderInstance,
    settings: AttendiMicrophoneSettings(
        size: 64,
        cornerRadius: 16,
        colors: AttendiMicrophoneDefaults.colors(baseColor: .red),
        isVolumeFeedbackEnabled: false
    ),
    onMicrophoneTapCallback: {
        print("Microphone tapped")
    },
    onRecordingPermissionDeniedCallback: {
        print("Microphone access denied")
    }
)
```

### Usage Examples

The following example screens demonstrate how to use `AttendiMicrophone` and `AttendiRecorder` in different real-world scenarios:

1. `OneMicrophoneSyncScreenView`:
Shows how to use `AttendiMicrophone` in a simple SwiftUI view without a ViewModel.

2. `RecorderStreamingScreenView`:
Demonstrates how to use the low-level `AttendiRecorder` directly, without integrating the `AttendiMicrophone` UI component.
Ideal for custom UIs or advanced use cases that require full control over recording flow.

3. `SoapScreenView`:
Integrates `AttendiMicrophone` into a complex SwiftUI layout with multiple TextEditor views.
Also demonstrates:
- How to disable the default permission denied alert (showsDefaultPermissionsDeniedAlert = false)
- How to present a custom alert using the onRecordingPermissionDeniedCallback

4. `TwoMicrophonesStreamingScreenView`:
Illustrates how to use two `AttendiMicrophone` components in the same view.
Each microphone operates independently with its own configuration and recorder instance, useful for multi-source streaming or comparative audio capture scenarios.

## Creating an AttendiRecorderPlugin

Plugins allow the `AttendiMicrophone` and `AttendiRecorder` component's functionality to be extended. The component exposes a plugin API consisting of functions that e.g. allow plugins to execute arbitrary logic at certain points in the component's lifecycle. A plugin is a class that inherits from the `AttendiRecorderPlugin` class.

The functionality of any plugin is implemented in its `activate` method. This method is called when the recorder is first initialized, and takes as input a reference to the recorderModel `AttendiRecorderModel`. Any logic that needs to run when the microphone is removed from the view should be implemented in the `deactivate` method. This might for instance be necessary when the plugin changes some global state. As an example, the `AttendiAsyncTranscribePlugin` plugin on activate it hooks the model to onStartRecording to create a service connection and on deactivate it closes the connection.

```swift
public final class AttendiAsyncTranscribePlugin: AttendiRecorderPlugin {

    private let service: AsyncTranscribeService

    public func activate(model: AttendiRecorderModel) async {
        await model.onStartRecording { [weak self, weak model] in
            guard let self, let model else { return }
            let serviceListener = createServiceListener(model: model)
            try await service.connect(listener: serviceListener)
        }
    }

    public  public func deactivate(model: AttendiRecorderModel) async {
        try? await service.disconnect()
    }
}
```

## Development

The project structure is organized as follows:

* AttendiSpeechService/
The core SDK framework target. This is the codebase for the Attendi Speech Service.

* AttendiSpeechServiceExample/
A sample iOS app demonstrating how to integrate and use the SDK.

* AttendiSpeechService.xcworkspace
A workspace file that groups both the SDK and the example app using their .xcodeproj files.
When contributing, editing, or running the project, always open the .xcworkspace instead of the individual .xcodeproj files to ensure all dependencies and project references work correctly.

* Package.swift
Enables integration of the AttendiSpeechService framework as a Swift Package (SPM). This allows consumers to install the SDK via Swift Package Manager.

* Scripts/swiftgen/
Contains SwiftGen configuration files.
SwiftGen is used to generate type-safe access to resources such as images, colors, and localized strings.
The AttendiSpeechService framework uses SwiftGen as part of its build process — the script is automatically run during build phases of the SDK target to generate resource access code.

## Issues

If you encounter any issues, don't hesitate to contact us at `omar@attendi.nl` or `emiliano@attendi.nl`.
