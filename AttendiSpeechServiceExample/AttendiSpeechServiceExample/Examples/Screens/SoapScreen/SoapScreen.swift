import SwiftUI

struct SoapScreen: View {

    private let viewModel = SoapScreenViewModel()

    var body: some View {
        SoapScreenView(model: Binding {
            viewModel.model
        } set: { newValue in
            viewModel.model = newValue
        })
    }
}
