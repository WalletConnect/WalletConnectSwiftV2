import SwiftUI

struct InviteView: View {

    @EnvironmentObject var presenter: InvitePresenter

    var body: some View {
        VStack(spacing: 32) {
            TextFieldView(title: "ENS Name or Public Key", placeholder: "username.eth or 0x0…", input: $presenter.input)

            if presenter.showButton {
                PlainButton {
                    try await presenter.invite()
                } label: {
                    HStack(spacing: 8.0) {
                        Image("plus_icon")
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Invite")
                            .foregroundColor(.w_foreground)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .padding(.trailing, 8.0)
                }
                .frame(width: 128, height: 44)
                .background(
                    Capsule()
                        .foregroundColor(.w_greenForground)
                )
            }

            Spacer()
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
