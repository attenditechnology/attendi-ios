/// Copyright 2023 Attendi Technology B.V.
/// 
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// 
///     http://www.apache.org/licenses/LICENSE-2.0
/// 
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import SwiftUI
import AVFoundation

let ATTENDI_BUTTON_SIZE: Double = 32.0

let recordingStartDelayMilliseconds = 500
let recordingStopDelayMilliseconds = 300

let defaultMicrophoneColor = Color(hex: "#1C69E8")


/// The ``AttendiMicrophone`` is a button that can be used to record audio and then perform tasks
/// with that audio, such as transcription. Recording is started by clicking the button, and
/// the recording can be stopped by clicking the button again.
///
/// The component is built with extensibility in mind. It can be extended with plugins that
/// add functionality to the component using the component's plugin APIs. Arbitrary logic can
/// for instance be executed at certain points in the component's lifecycle, such as before
/// recording starts, or when an error occurs, by registering callbacks using
/// the ``AttendiMicrophone/Callbacks-swift.class/onBeforeStartRecording(_:)`` or
/// ``AttendiMicrophone/Callbacks-swift.class/onError(_:)`` methods.
/// See the ``AttendiMicrophonePlugin`` interface for more information.
///
/// - Example:
/// ```swift
/// AttendiMicrophone(
///     microphoneModifier: AttendiMicrophoneModifier(size: 56, color: Color.red),
///     plugins: [
///         AttendiErrorPlugin(),
///         AttendiTranscribePlugin(apiConfig: apiConfig)
///     ]
/// ) { text in
///     textFieldText = text
/// }
/// .padding(8)
/// ```
public struct AttendiMicrophone: View {
    /// Represents one of the visual states the microphone is in. The UIState is one of the main properties
    /// that determines what the UI of the microphone looks like and how clicks are handled.
    public enum UIState: String, Codable {
        case notStartedRecording, loadingBeforeRecording, recording, processingRecording
    }
    
    // We can't call it `Error` as this somehow messes with Swift.
    public enum Errors: Error {
        case noPermission
        case cantStartRecording
        case invalidResponse
        case general(message: String)
    }
    
    public enum Variant {
        case normal
        case transparent
        case white
    }

    public enum OptionsVariant {
        case normal
        case always
        case hidden
    }
    
    class Settings: ObservableObject {
        public init(
            color: Color? = nil,
            showOptions: AttendiMicrophone.OptionsVariant? = nil,
            size: Double? = nil,
            cornerRadius: Double? = nil,
            variant: AttendiMicrophone.Variant? = nil,
            silent: Bool? = nil,
            customUIIcons: [String : AnyView]? = nil
        ) {
            self.color = color ?? defaultMicrophoneColor
            self.showOptions = showOptions ?? .hidden
            self.size = size ?? 56
            self.cornerRadius = cornerRadius ?? 1000
            self.variant = variant ?? .normal
            self.silent = silent ?? false
            self.customUIIcons = customUIIcons ?? [:]
        }
        
        @Published var color: Color
        @Published var showOptions: AttendiMicrophone.OptionsVariant
        @Published var size: Double
        @Published var cornerRadius: Double
        @Published var variant: AttendiMicrophone.Variant
        @Published var silent: Bool
        // TODO: remove `customUIIcons` -> make into plugin API
        @Published var customUIIcons: [String: AnyView]
    }
    
    /// Contains settings that are used throughout the AttendiMicrophone and descendant views, such
    /// as the size of the component.
    @StateObject var settings = Settings()
    
    @State var plugins: [AttendiMicrophonePlugin] = []
    
    @State var animatedMicrophoneFillLevel: Double = 0
    
    @State public var uiState = AttendiMicrophone.UIState.notStartedRecording {
        didSet {
            if uiState != oldValue {
                for callback in callbacks.UIStateCallbacks.values {
                    Task {
                        await callback(uiState)
                    }
                }
            }
        }
    }
    
    /// [PLUGIN API]
    /// Keep track of the plugin API callbacks' state.
    @State public var callbacks = Callbacks()
    
    /// We want to be able to run some logic just on the first interaction with the component. We know whether it's
    /// the first interaction because of this variable.
    @State var hasClicked = false
    
    /// [PLUGIN API]
    /// Contains the functionality for recording audio from the device.
    @State public var recorder = AttendiRecorder()
    
    /// [PLUGIN API]
    /// Use to play sounds.
    @State public var audioPlayer = AttendiAudioPlayerDelegate()
    
    /// An audio task represents something we want to do with the audio recorded by the microphone.
    /// It is a list of callbacks that take as input the recorded audio data in a wav representation. Clients can
    /// call ``registerAudioTask`` and ``setActiveAudioTask`` to register and set the audio tasks
    /// they want to perform.
    @State var audioTasks: [String: (Data) async -> Void] = [:]
    
    /// Clients can register multiple audio tasks with the component. But sometimes we only want to perform a subset
    /// of the registered tasks. The concept of active audio tasks exist to separate the audio tasks we register from the one
    /// we want to perform at a moment in time.
    @State var activeAudioTasks = Set<String>()
    
    /// Keeping track of the history is necessary as plugins can change the active audio task. But they don't necessarily know what
    /// other audio tasks exist. To undo their changes, they can use the ``activeAudioTaskHistory``.
    @State var activeAudioTaskHistory: [Set<String>] = []
    
    /// To give more feedback to the user, the microphone plays sounds when recording is started, stopped, and when errors occur.
    /// To disable this, set this parameter to true.
    let silent: Bool
    
    /// This callback allows plugins to send arbitrary events to the ``AttendiMicrophone``'s
    /// caller. This can be useful when the result is not just a string, but an arbitrary
    /// data structure. The caller can branch on the event name to handle the event(s) it
    /// cares about
    let onEvent: (String, Any) -> Void
    
    /// Use this callback to access any results that can be represented
    /// as a string such as transcriptions. Plugins are able to call this callback
    /// to return results.
    let onResult: (String) -> Void
    
    /// - Parameter microphoneModifier: Use this to change certain aspects of the microphone's appearance.
    /// To see what properties can be changed, see ``AttendiMicrophoneModifier``.
    /// - Parameter plugins: Functionality can be added to this component through a plugin system.
    /// See the ``AttendiMicrophonePlugin`` interface for more information.
    /// - Parameter silent: By default, the component will play a sound when the recording is
    /// started and stopped, and when an error occurs. This can be disabled by setting
    /// this attribute to `true`.
    /// - Parameter showOptions: Currently not used. If set to `true`, the component will expand to show an options button.
    /// When clicked, an options menu is shown in a bottom sheet.
    /// - Parameter onResult: Use this callback to access any results that can be represented
    /// as a string such as transcriptions. Plugins are able to call this callback
    /// to return results.
    /// - Parameter onEvent: This callback allows plugins to send arbitrary events to the ``AttendiMicrophone``
    /// caller. This can be useful when the result is not just a string, but an arbitrary
    /// data structure. The caller can branch on the event name to handle the event(s) it
    /// cares about.
    public init(
        microphoneModifier: AttendiMicrophoneModifier = AttendiMicrophoneModifier(),
        showOptions: Bool = false,
        plugins: [AttendiMicrophonePlugin] = [],
        silent: Bool = false,
        onResult: @escaping (String) -> Void = { _ in},
        onEvent: @escaping (String, Any) -> Void = { _, _ in }
    ) {
        self._settings = StateObject(wrappedValue: Settings(
            color: microphoneModifier.color,
            showOptions: showOptions ? .normal : .hidden,
            size: microphoneModifier.size,
            cornerRadius: microphoneModifier.cornerRadius
        ))
        
        let defaultPlugins = [AudioNotificationPlugin(), VolumeFeedbackPlugin()]
        
        // Set state directly so we can use it in the `onAppear` function to activate the plugins.
        self._plugins = State(initialValue: defaultPlugins +  plugins)
        
        self.silent = silent
        
        self.onEvent = onEvent
        self.onResult = onResult
    }
    
    public var body: some View {
        let showOptions = self.shouldShowOptions()
        
        let size = self.settings.size
        
        let width = size + (showOptions ? size : 0)
        
        ZStack {
            // Show a border around the component if showOptions is true
            if showOptions {
                RoundedRectangle(cornerRadius: self.settings.cornerRadius)
                    .stroke(self.settings.color)
            }
            
            HStack(spacing: 0) {
                ZStack(alignment: .center) {
                    getView()
                        .frame(width: size, height: size)
                        .alwaysPopover(isPresented: $tooltipVisible) {
                            Text(self.tooltipText)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: 200)
                        }
                    
                    OptionsMenuView(isOpen: self.$isOptionsMenuVisible, menuGroups: menuGroups, menuItems: menuItems)
                }
                .frame(width: size, height: size)
                
                if showOptions {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(self.settings.color)
                            .padding(.top, size * 0.2)
                            .padding(.bottom, size * 0.2)
                            .frame(width: 1, alignment: .leading)
                        Button(action: {
                            self.isOptionsMenuVisible.toggle()
                        }) {
                            getOptionsView(size: size)
                        }
                        .frame(width: size, height: size)
                    }
                }
            }
        }
        .frame(width: width, height: size)
        .environmentObject(settings)
        .onAppear {
            plugins.forEach { $0.activate(self) }
        }
        .onDisappear {
            plugins.forEach { $0.deactivate(self) }
        }
    }
    
    private func shouldShowOptions() -> Bool {
        let isInactive = uiState == .notStartedRecording || uiState == .loadingBeforeRecording
        
        return self.settings.showOptions == .always || (self.settings.showOptions == .normal && isInactive)
    }
    
    func getView() -> some View {
        let view: any View
        
        switch uiState {
        case .notStartedRecording:
            view = MicrophoneNotStartedRecordingView()
        case .loadingBeforeRecording:
            view = MicrophoneLoadingBeforeRecordingView()
        case .recording:
            view = MicrophoneRecordingView(animatedMicrophoneFillLevel: animatedMicrophoneFillLevel)
        case .processingRecording:
            view = MicrophoneProcessingRecordingView()
        }
        
        return Button(action: {
            if !hasClicked {
                hasClicked = true
                // TODO: maybe not put in a task, so that we really only start after first interaction callbacks
                //      are finished.
                Task {
                    do {
                        for callback in callbacks.firstClickCallbacks.values {
                            await callback()
                        }
                    }
                }
            }
            
            if uiState == .notStartedRecording {
                start()
            } else if uiState == .recording {
                Task {
                    do {
                        await stop()
                    }
                }
            }
        }) {
            AnyView(view)
        }
        // These states are not clickable
        .disabled(uiState == .loadingBeforeRecording || uiState == .processingRecording)
    }
    
    public func start() {
        requestMicrophonePermission { allowed in
            if !allowed {
                Task {
                    do {
                        for callback in self.callbacks.errorCallbacks.values {
                            await callback(.noPermission)
                        }
                    }
                }
                return
            }
            
            // We are allowed to start recording.
            Task {
                do {
                    uiState = .loadingBeforeRecording
                    
                    // Run all the onBeforeRecording events before turning on the microphone
                    for callback in callbacks.beforeStartRecordingCallbacks.values {
                        await callback()
                    }
                    
                    do {
                        try recorder.startRecording()
                        
                        for callback in callbacks.startRecordingCallbacks.values {
                            await callback()
                        }
                        
                        // Simulate loading time before recording so that the user doesn't start speaking before
                        // the recording has started.
                        try? await Task.sleep(nanoseconds: UInt64(recordingStartDelayMilliseconds * 1_000_000))
                        
                        uiState = .recording
                    } catch {
                        recorder.stopRecording()
                        uiState = .notStartedRecording
                        
                        for callback in self.callbacks.errorCallbacks.values {
                            await callback(.cantStartRecording)
                        }
                    }
                }
            }
        }
    }
    
    /// Request permission to use the microphone to the user. If the user has
    /// has already granted or denied permission, the completion handler will be
    /// called immediately. If the user has not yet been asked for permission, the
    /// user will be prompted for permission and the completion handler will be
    /// called once the user has responded.
    ///
    /// - Parameter completion: A closure that will be called with the result of
    ///   the permission request. The closure will be called immediately if the
    ///   user has already granted or denied permission. Otherwise, the closure
    ///   will be called once the user has responded to the permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            audioSession.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    completion(allowed)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    public func stop() async {
        // Run all the onBeforeStopRecording events before turning off the microphone
        for callback in callbacks.beforeStopRecordingCallbacks.values {
            await callback()
        }
        
        uiState = .processingRecording
        
        // The last word is oftentimes not correctly transcribed.
        // This might be a result of a user still uttering the last syllable
        // while already pressing the stop button. The timeout allows recording
        // for just a bit longer before stopping the recorder, so that we also get
        // the last bit of spoken audio.
        try? await Task.sleep(nanoseconds: UInt64(recordingStopDelayMilliseconds * 1_000_000))
        
        recorder.stopRecording()
        
        // Run all the onStopRecording callbacks after turning of the microphone
        for callback in callbacks.stopRecordingCallbacks.values {
            await callback()
        }
        
        let audioData = pcmToWav(samples: recorder.buffer, sampleRate: targetSampleRate)
        recorder.clearBuffer()
        
        for taskId in activeAudioTasks {
            if let audioTask = audioTasks[taskId]  {
                await audioTask(audioData)
            }
        }
        
        Task { @MainActor in
            uiState = .notStartedRecording
        }
    }
    
    @ViewBuilder
    private func getOptionsView(size: Double) -> some View {
        if let possibleCustomView = settings.customUIIcons["options"] {
            possibleCustomView
                .foregroundColor(settings.color)
                .padding(8)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "chevron.down")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.color)
                .frame(width: size * 0.35, height: size * 0.35)
        }
    }
    
    // MARK: ============= Options menu =============
    
    @State var isOptionsMenuVisible: Bool = false
    
    @State private var menuGroups: [MenuGroup] = []
    @State private var menuItems: [String: [MenuItem]] = [:]
    
    /// [PLUGIN API]
    /// Add a menu group to the options menu. 
    @discardableResult
    public func addMenuGroup(_ group: MenuGroup) -> () -> Void {
        menuGroups.append(group)
        menuGroups.sort { $0.priority < $1.priority }
        
        return { menuGroups.removeAll { $0 == group } }
    }
    
    /// [PLUGIN API]
    /// Add a menu item to the options menu.
    @discardableResult
    public func addMenuItem(_ item: MenuItem) -> () -> Void {
        if menuItems[item.group] != nil {
            menuItems[item.group]?.append(item)
        } else {
            menuItems[item.group] = [item]
        }
        
        return {
            menuItems[item.group]?.removeAll { $0 == item }
        }
    }
    
    // MARK: ============= Tooltip =============
    
    @State var tooltipText: String = ""
    @State var tooltipVisible: Bool = false
    
    /// [PLUGIN API]
    /// Show a tooltip (popover) next to the component.
    public func showTooltip(_ text: String) {
        self.tooltipText = text
        self.tooltipVisible = true
    }
}

/**
 * Used to change aspects of the microphone's appearance.
 */
public struct AttendiMicrophoneModifier {
    public init(size: Double? = nil, color: Color? = nil, cornerRadius: Double? = nil) {
        self.size = size
        self.color = color
        self.cornerRadius = cornerRadius
    }
    
    /// The main color of the microphone.
    public let color: Color?
    
    /// Sets the width and height of the microphone. If showOptions is false, the width and height
    /// will be equal. If showOptions is true, the width will be twice the height.
    public let size: Double?
    
    /// Sets the corner radius of the microphone. If not set, the button will have a circular shape.
    public let cornerRadius: Double?
}

struct AttendiMicrophoneButton_Previews: PreviewProvider {
    @State static var text: String = ""
    
    static var previews: some View {
        AttendiMicrophone(plugins: [
            AttendiTranscribePlugin(
                apiConfig: TranscribeAPIConfig(
                    apiURL: "https://sandbox.api.attendi.nl",
                    customerKey: "ck_<key>",
                    userId: "userId",
                    unitId: "unitId",
                    modelType: .districtCare
                )
            )]
        ) { transcript in
            text = transcript
        }
        .cornerRadius(20)
    }
}

struct MicrophoneNotStartedRecordingView: View {
    @EnvironmentObject var settings: AttendiMicrophone.Settings
    
    func foregroundColor() -> Color {
        switch settings.variant {
        case .white: return .white
        case .normal: return settings.color
        case .transparent: return settings.color
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image("microphone", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(foregroundColor())
                .frame(width: geometry.size.width * 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}


struct MicrophoneNotStartedRecording_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneNotStartedRecordingView()
            .environmentObject(AttendiMicrophone.Settings())
    }
}

struct MicrophoneLoadingBeforeRecordingView: View {
    @EnvironmentObject var settings: AttendiMicrophone.Settings
    @State private var rotation = 0.0
    
    func backgroundColor() -> Color {
        switch settings.variant {
        case .white: return Color.clear
        case .normal: return settings.color
        case .transparent: return Color.clear
        }
    }
    
    func foregroundColor() -> Color {
        switch settings.variant {
        case .white: return .white
        case .normal: return settings.color
        case .transparent: return settings.color
        }
    }
    
    var body: some View {
        let showOptions = settings.showOptions == .always || settings.showOptions == .normal
        
        ZStack {
            if showOptions {
                Rectangle()
                    .fill(backgroundColor())
                    .opacity(0.2)
                    .frame(width: ATTENDI_BUTTON_SIZE, height: ATTENDI_BUTTON_SIZE)
//                    .cornerRadius(settings.cornerRadius, corners: [.topLeft, .bottomLeft])
            }
            
            getView()
        }
    }
    
    @ViewBuilder
    private func getView() -> some View {
        if let possibleCustomView = settings.customUIIcons[AttendiMicrophone.UIState.loadingBeforeRecording.rawValue] {
            possibleCustomView
                .padding(8)
                .foregroundColor(foregroundColor())
        } else {
            GeometryReader { geometry in
                Image("attendiLogo", bundle: .module)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(foregroundColor())
                    .rotationEffect(.degrees(rotation))
                    .frame(width: geometry.size.width * 0.35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .onAppear {
                        withAnimation(
                            .timingCurve(0.715, 0.15, 0.175, 0.84, duration: 0.8)
                            .repeatForever(autoreverses: false)) {
                                rotation = 360.0
                            }
                    }
            }
        }
    }
}

struct MicrophoneLoadingBeforeStart_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneLoadingBeforeRecordingView()
            .environmentObject(AttendiMicrophone.Settings())
    }
}

struct MicrophoneRecordingView: View {
    @EnvironmentObject var settings: AttendiMicrophone.Settings
    
    var animatedMicrophoneFillLevel: CGFloat = 0
    
    @State var activeListeners: Array<(() -> Void)> = []
    
    func backgroundColor() -> Color {
        switch settings.variant {
        case .white: return Color.clear
        case .normal: return settings.color
        case .transparent: return Color.clear
        }
    }
    
    func foregroundColor() -> Color {
        switch settings.variant {
        case .white: return .white
        case .normal: return .white
        case .transparent: return settings.color
        }
    }
    
    var body: some View {
        let showOptions = settings.showOptions == .always
        
        let view = getView()
            .background(backgroundColor().ignoresSafeArea())
        
        // If showOptions is true, we need to have control over the different corners' corner
        // radii. However, using our own cornerRadius modifier doesn't result in a perfect circle,
        // even when the cornerRadius is large enough. Therefore we use SwiftUI's normal `cornerRadius`
        // modifier when `showOptions` is false.
        if showOptions {
            return AnyView(view
                .cornerRadius(settings.cornerRadius, corners: [.topLeft, .bottomLeft])
                .cornerRadius(0 , corners: [.topRight, .bottomRight])
            )
        } else {
            return AnyView(view.cornerRadius(settings.cornerRadius))
        }
    }
    
    @ViewBuilder
    private func getView() -> some View {
        if let possibleCustomView = settings.customUIIcons[AttendiMicrophone.UIState.recording.rawValue] {
            possibleCustomView
                .foregroundColor(foregroundColor())
        } else {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    Image("microphone", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(foregroundColor())
                        .frame(width: geometry.size.width * 0.5)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(foregroundColor())
                        .frame(width: geometry.size.width * 0.18, height: geometry.size.height * 0.24 * max(min(animatedMicrophoneFillLevel, 1), 0))
                        .animation(.linear(duration: 0.08))
                        .padding(.bottom, geometry.size.height * 0.19)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

struct MicrophoneRecording_Previews: PreviewProvider {
    static let client = AttendiClient()
    
    static var previews: some View {
        MicrophoneRecordingView(animatedMicrophoneFillLevel: 0.5)
            .frame(width: 64, height: 64)
            .environmentObject(AttendiMicrophone.Settings())
    }
}

struct MicrophoneProcessingRecordingView: View {
    @EnvironmentObject var settings: AttendiMicrophone.Settings
    @State private var scales: [CGFloat] = [0.1, 0.1, 0.1, 0.1, 0.1]
    
    func backgroundColor() -> Color {
        switch settings.variant {
        case .white: return Color.clear
        case .normal: return settings.color
        case .transparent: return Color.clear
        }
    }
    
    func foregroundColor() -> Color {
        switch settings.variant {
        case .white: return .white
        case .normal: return .white
        case .transparent: return settings.color
        }
    }
    
    var body: some View {
        let showOptions = settings.showOptions == .always
        
        let view = GeometryReader { geometry in
            HStack(spacing: geometry.size.width * 0.035) {
                getView(parentSize: geometry.size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
            .background(backgroundColor().ignoresSafeArea())
        
        if showOptions {
            return AnyView(view
                .cornerRadius(settings.cornerRadius, corners: [.topLeft, .bottomLeft])
                .cornerRadius(0 , corners: [.topRight, .bottomRight])
            )
        } else {
            return AnyView(view.cornerRadius(settings.cornerRadius)
            )
        }
    }
    
    @ViewBuilder
    private func getView(parentSize: CGSize) -> some View {
        if let possibleCustomView = settings.customUIIcons[AttendiMicrophone.UIState.processingRecording.rawValue] {
            possibleCustomView
                .foregroundColor(foregroundColor())
        } else {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(foregroundColor())
                    .frame(width: parentSize.width * 0.05, height: parentSize.height * 0.5)
                    .scaleEffect(y: scales[index])
                    .animation(Animation.easeInOut(duration: 0.8).repeatForever().delay(0.1 * Double(index)))
                    .onAppear {
                        withAnimation {
                            self.scales[index] = 1
                        }
                    }
            }
        }
    }
}

struct MicrophoneProcessing_Previews: PreviewProvider {
    static var previews: some View {
        MicrophoneProcessingRecordingView()
            .environmentObject(AttendiMicrophone.Settings())
    }
}
