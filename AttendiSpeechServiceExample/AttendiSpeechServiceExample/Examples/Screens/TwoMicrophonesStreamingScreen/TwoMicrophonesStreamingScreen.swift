import SwiftUI

struct TwoMicrophonesStreamingScreen: View {

    private let viewModel = TwoMicrophonesStreamingScreenViewModel()

    var body: some View {
        NavigationStack {
            TwoMicrophonesStreamingScreenView(model: Binding {
                viewModel.model
            } set: { newValue in
                viewModel.model = newValue
            })
            .navigationTitle("Two Microphones Streaming")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
