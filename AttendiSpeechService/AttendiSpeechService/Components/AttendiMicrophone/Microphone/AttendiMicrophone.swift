import SwiftUI

/// A customizable microphone button component for recording audio and triggering plugin-based behavior,
/// such as transcription, audio feedback, or contextual actions.
///
/// This view coordinates with a provided `AttendiRecorder` instance and manages visual state and user
/// interactions.
///
/// ### Example usage:
/// ```swift
/// AttendiMicrophone(
///     recorder: recorderInstance,
///     settings: AttendiMicrophoneSettings(
///         size: 64,
///         cornerRadius: 16,
///         colors: AttendiMicrophoneDefaults.colors(baseColor: .red)
///     )
/// )
/// ```
///
/// - Parameters:
///   - recorder: The `AttendiRecorder` instance that handles low-level audio recording logic.
///     This is a required dependency that provides the interface for starting and stopping audio capture.
///   - settings: An optional `AttendiMicrophoneSettings` value used to configure the appearance,
///     shape, and feedback behavior (e.g., color, size, corner radius) of the microphone button.
///   - onMicrophoneTapCallback: An optional closure called after the microphone is activated. Use this
///     to trigger custom logic after a tap interaction.
///   - onRecordingPermissionDeniedCallback: An optional closure called when the app fails to obtain
///     the required microphone permissions.
///     When setting `showsDefaultPermissionsDeniedAlert` to false  in `AttendiMicrophoneSettings`, use this
///     callback to handle denied access, show alerts, or guide the user to settings.
public struct AttendiMicrophone: View {

    @StateObject private var viewModel: AttendiMicrophoneViewModel
    @State private var showPermanentlyDeniedAlert = false

    private let settings: AttendiMicrophoneSettings

    public init(
        recorder: AttendiRecorder,
        settings: AttendiMicrophoneSettings = AttendiMicrophoneSettings(),
        onMicrophoneTapCallback: @escaping () -> Void = { },
        onRecordingPermissionDeniedCallback: @escaping () -> Void = { }
    ) {
        _viewModel = .init(wrappedValue: AttendiMicrophoneViewModel(
            recorder: recorder,
            microphoneSettings: settings,
            onMicrophoneTapCallback: onMicrophoneTapCallback,
            onRecordingPermissionDeniedCallback: onRecordingPermissionDeniedCallback
        ))
        self.settings = settings
    }

    public var body: some View {
        ZStack {
            AttendiMicrophoneView(
                settings: settings,
                microphoneUIState: viewModel.microphoneUIState,
                onTap: {
                    viewModel.onTap()
                }
            )
            .onChange(of: viewModel.microphoneUIState.shouldVerifyAudioPermission) { shouldVerifyAudioPermission in
                if shouldVerifyAudioPermission {
                    handlePermissionStatus()
                }
            }

            if showPermanentlyDeniedAlert {
                AudioPermissionDeniedAlert(isPresented: $showPermanentlyDeniedAlert) {
                    showPermanentlyDeniedAlert = false
                }
            }
        }
    }

    private func handlePermissionStatus() {
        Task { @MainActor in
            AudioPermissionVerifier.requestMicrophonePermission { result in
                switch result {
                case .alreadyGranted:
                    viewModel.onAlreadyGrantedRecordingPermissions()

                case .justGranted:
                    viewModel.onJustGrantedRecordingPermissions()

                case .denied:
                    viewModel.onDeniedPermissions()
                    if settings.showsDefaultPermissionsDeniedAlert {
                        showPermanentlyDeniedAlert = true
                    }
                }
            }
        }
    }
}

private struct AudioPermissionDeniedAlert: View {

    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 0, height: 0)
            .alert(L10n.NoMicrophone.Permission.Dialog.title, isPresented: $isPresented) {
                Button(L10n.NoMicrophone.Permission.Dialog.Cancel.button, role: .cancel) {
                    onDismiss()
                }
                Button(L10n.NoMicrophone.Permission.Dialog.GoToSettings.button) {
                    openAppSettings()
                    onDismiss()
                }
            } message: {
                Text(L10n.NoMicrophone.Permission.Dialog.body)
            }
            .onChange(of: isPresented) { isPresented in
                if isPresented {
                    Vibrator.vibrate(.warning)
                }
            }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

private struct AttendiMicrophoneView: View {
    let settings: AttendiMicrophoneSettings
    let microphoneUIState: AttendiMicrophoneUIState
    let onTap: () -> Void

    var body: some View {
        let width = settings.size
        let height = settings.size
        let cornerRadius = settings.cornerRadius ?? .infinity

        HStack {
            ZStack {
                contentView
            }
            .frame(width: width, height: height)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture {
                onTap()
            }
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private var contentView: some View {
        switch microphoneUIState.state {
        case .idle:
            NotStartedRecordingView(settings: settings)
        case .loading:
            LoadingBeforeRecordingView(settings: settings)
        case .recording:
            RecordingView(
                settings: settings,
                animatedMicrophoneFillLevel: microphoneUIState.animatedMicrophoneFillLevel
            )
        case .processing:
            ProcessingView(settings: settings)
        }
    }
}

private struct NotStartedRecordingView: View {
    let settings: AttendiMicrophoneSettings

    var body: some View {
        GeometryReader { geometry in
            Asset.Images.microphone.swiftUIImage
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(settings.colors.inactiveForegroundColor)
                .frame(width: geometry.size.width * 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(settings.colors.inactiveBackgroundColor)
                .accessibilityLabel(Text(L10n.Microphone.NotRecording.title))
        }
    }
}

private struct LoadingBeforeRecordingView: View {
    let settings: AttendiMicrophoneSettings

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            settings.colors.inactiveBackgroundColor
                .ignoresSafeArea()

            GeometryReader { geometry in
                Asset.Images.loading.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(settings.colors.inactiveForegroundColor)
                    .rotationEffect(.degrees(rotation))
                    .frame(width: geometry.size.width * 0.35)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(settings.colors.inactiveBackgroundColor)
                    .accessibilityLabel(Text(L10n.Microphone.Loading.title))
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

private struct RecordingView: View {
    let settings: AttendiMicrophoneSettings
    let animatedMicrophoneFillLevel: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                Asset.Images.microphone.swiftUIImage
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width * 0.5)
                    .accessibilityLabel(Text(L10n.Microphone.Recording.title))

                RoundedRectangle(cornerRadius: 4)
                    .frame(
                        width: geometry.size.width * 0.18,
                        height: geometry.size.height * 0.24 * max(min(animatedMicrophoneFillLevel, 1), 0)
                    )
                    .padding(.bottom, geometry.size.height * 0.19)
                    .animation(
                        .interactiveSpring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.25),
                        value: animatedMicrophoneFillLevel
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .foregroundColor(settings.colors.activeForegroundColor)
            .background(settings.colors.activeBackgroundColor)
        }
    }
}

private struct ProcessingView: View {
    let settings: AttendiMicrophoneSettings

    @State private var scales: [CGFloat] = [0.1, 0.1, 0.1, 0.1, 0.1]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: geometry.size.width * 0.035) {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(settings.colors.activeForegroundColor)
                        .frame(width: geometry.size.width * 0.05, height: geometry.size.height * 0.5)
                        .scaleEffect(y: scales[index])
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever().delay(0.1 * Double(index)), value: scales)
                        .onAppear {
                            withAnimation {
                                self.scales[index] = 1
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(L10n.Microphone.Processing.title)
        }
        .background(settings.colors.activeBackgroundColor.ignoresSafeArea())
    }
}

private struct ProcessingAnimation: View {
    let foregroundColor: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<5) { index in
                Spacer()
                AnimatedRectangle(index: index, color: foregroundColor)
                Spacer()
            }
        }
        .frame(maxHeight: .infinity)
        .frame(width: UIScreen.main.bounds.width * 0.6)
        .animation(.default, value: UUID())
    }
}

private struct AnimatedRectangle: View {
    let index: Int
    let color: Color
    @State private var scale: CGFloat = 0.1

    var body: some View {
        GeometryReader { geometry in
            let maxWidth = geometry.size.width
            let maxHeight = geometry.size.height
            let width = min(maxWidth * 0.1, 3)
            let height = maxHeight * 0.4 * scale

            Rectangle()
                .fill(color)
                .frame(width: width, height: height)
                .onAppear {
                    withAnimation(
                        Animation.easeInOut(duration: 0.8)
                            .delay(Double(index) * 0.1)
                            .repeatForever(autoreverses: true)
                    ) {
                        scale = 1.0
                    }
                }
        }
        .frame(maxHeight: .infinity)
    }
}
