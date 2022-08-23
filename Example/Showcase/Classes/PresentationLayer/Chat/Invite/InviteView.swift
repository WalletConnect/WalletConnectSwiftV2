import SwiftUI

struct InviteView: View {

    @EnvironmentObject var presenter: InvitePresenter

    var body: some View {
        VStack {
            TextFieldView(title: "ENS Name or Public Key", placeholder: "username.eth or 0x0…", input: $presenter.input)
            Spacer()
        }.task {
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
