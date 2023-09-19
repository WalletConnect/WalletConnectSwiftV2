import SwiftUI

struct NotifyPreferencesView: View {

    @EnvironmentObject var viewModel: NotifyPreferencesPresenter

    var body: some View {
        Text("NotifyPreferences module")
    }
}

#if DEBUG
struct NotifyPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NotifyPreferencesView()
    }
}
#endif
