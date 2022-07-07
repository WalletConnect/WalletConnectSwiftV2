import SwiftUI

struct InviteListView: View {

    @EnvironmentObject var presenter: InviteListPresenter

    var body: some View {
        Text("InviteList module")
            .task {
                await presenter.setupInitialState()
            }
    }
}

#if DEBUG
struct InviteListView_Previews: PreviewProvider {
    static var previews: some View {
        InviteListView()
    }
}
#endif
