# Attendi Speech Service for iOS

The Attendi Speech Service iOS SDK provides the `AttendiMicrophone` component: a `SwiftUI` microphone button that can be used to record audio and perform arbitrary tasks with that audio, such as audio transcription.

The component is built with extensibility in mind. It can be extended with plugins that add functionality to the component using the component's plugin APIs. Arbitrary logic can for instance be executed at certain points in the component's lifecycle, such as before recording starts, or when an error occurs.

The `AttendiClient` class provides an interface to easily communicate with the Attendi Speech Service backend APIs.

## Getting started

The SDK is available as a `Swift` package.

To utilize the Attendi Speech Service iOS package, you need to first include it as a dependency in your app.

You have to option to install it manually:

1. Clone the Repository:

Clone the "AttendiSpeechService" GitHub repository to your local machine using git clone.

2. Add Package:

- Go to Project Settings > Frameworks, Libraries and Embedded Content.
- Click "+" to Add Package Dependency
- Enter the local path to the cloned "AttendiSpeechService" repository
- Select Package: Choose "AttendiSpeechService" from the list

3. Integration: Xcode will integrate the package from the local repository.

Also, you can incorporate the client into your project by including it as a dependency in your Package.swift file, as it's distributed through Swift Package Manager: 

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .package(name: "attendispeechservice", url: "https://github.com/attenditechnology/attendi-ios.git", path: "AttendiSpeechService"),
    ],
    targets: [
        .target(
            name: "AttendiSpeechService",
            dependencies: []),
        .testTarget(
            name: "AttendiSpeechServiceTests",
            dependencies: ["MyApp"]),
```

and run `swift package update`

After installing and building the package, you can use the microphone component in your project:

```swift
import AttendiSpeechService

// within some SwiftUI view

AttendiMicrophone(
    // Change aspects of the microphone's appearance, such as size and color,
    // using the `microphoneModifier` parameter
    microphoneModifier: AttendiMicrophoneModifier(size: 56, color: Color.red),
    // Add plugins if necessary. These extend the functionality of the microphone component.
    plugins: [
        // Tells microphone what to do when an error occurs.
        AttendiErrorPlugin(),
        // Transcribes audio using the Attendi Speech Service.
        AttendiTranscribePlugin(apiConfig: apiConfig),
    ]
    // The transcribe plugin calls an `onResult` callback when the transcription result is available.
    // This allows the client to access the transcription result and do something with it.
) { text in
    print(text)
}
// We can use view modifiers as usual here.
.padding(8)
```

In the example above, the `AttendiMicrophone` component is used to transcribe audio. The `AttendiTranscribePlugin` plugin adds the transcription functionality and the `AttendiErrorPlugin` plugin tells the component what to do when an error occurs.

For more details on the `AttendiMicrophone`'s API, see its Swift documentation.

## Communicating with the `AttendiMicrophone` component

The `AttendiMicrophone` exposes two callbacks in its initializer: `onEvent` and `onResult`. The `onResult` callback can be called by plugins when they want to signal a result to the client when that result is in text (string) form. As seen in the example above, the text can be accessed by the client by providing a closure to the `onResult` parameter.

The `onEvent` callback can be called by plugins when they want to signal a more general event to the client. Plugins can call `onEvent` and pass it an event name and a result object. The client can then listen for these events by providing a closure to the `onEvent` parameter. The client can then check the event name and the result object to determine what to do.

## Styling

The microphone component can be styled using the `microphoneModifier` parameter. See the `AttendiMicrophoneModifier`'s Swift documentation for more details.

## Creating a plugin

**Warning: the microphone's plugin APIs are still under development and subject to change.**

Plugins allow the microphone component's functionality to be extended. The component exposes a plugin API consisting of functions that e.g. allow plugins to execute arbitrary logic at certain points in the component's lifecycle. A plugin is a class that inherits from the `AttendiMicrophonePlugin` class.

The functionality of any plugin is implemented in its `activate` method. This method is called when the microphone is first initialized, and takes as input a reference to the corresponding microphone component. Any logic that needs to run when the microphone is removed from the view should be implemented in the `deactivate` method. This might for instance be necessary when the plugin changes some global state. As an example, the `AttendiErrorPlugin` plugin is implemented as follows:

```swift
/// Does the following when an error occurs:
/// - vibrate the device
/// - show a tooltip with an error message next to the microphone
public class AttendiErrorPlugin: AttendiMicrophonePlugin {
    // The `activate` method is called when the microphone is first initialized and takes as input a reference to the microphone component.
    public override func activate(_ mic: AttendiMicrophone) {
        Task { @MainActor in
            // Use the `mic.callbacks.onError` plugin API to add a callback that is called when an error occurs.
            mic.callbacks.onError { error in
                // Use the `mic.audioPlayer.playSound` plugin API to play a sound.
                mic.audioPlayer.playSound(sound: "error_notification")

                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()

                // Use the `showToolTip` plugin API to show a tooltip with an error message next to the microphone.
                mic.showTooltip("An error occurred")
            }
        }
    }
}
```

While an exhaustive list of plugin APIs is not yet available here, all plugin APIs are annotated in Swift documentation with `[PlUGIN API]`. The lifecycle callbacks are available in using `mic.callbacks` as shown above.

## Issues

If you encounter any issues, don't hesitate to contact us at `omar@attendi.nl`.