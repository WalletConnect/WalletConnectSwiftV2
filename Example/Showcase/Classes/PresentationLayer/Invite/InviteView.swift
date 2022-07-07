import SwiftUI

struct InviteView: View {

    @EnvironmentObject var presenter: InvitePresenter

    var body: some View {
        Text("Invite module")
            .task {
                await presenter.setupInitialState()
            }
    }
}

#if DEBUG
struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView()
    }
}
#endif
