import SwiftUI

struct OneMicrophoneSyncScreen: View {

    var body: some View {
        NavigationStack {
            OneMicrophoneSyncScreenView()
            .navigationTitle("One Microphone Sync")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
