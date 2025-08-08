import SwiftUI

struct RecorderStreamingScreen: View {

    private let viewModel = RecorderStreamingScreenViewModel()

    var body: some View {
        NavigationStack {
            RecorderStreamingScreenView(model: Binding {
                viewModel.model
            } set: { newValue in
                viewModel.model = newValue
            })
            .navigationTitle("Recorder")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
