import SwiftUI

struct InviteView: View {

    @EnvironmentObject var presenter: InvitePresenter

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("ENS Name or Public Key")
                    .font(.subheadline)
                    .foregroundColor(.w_secondaryForeground)
                    .padding(.horizontal, 16.0)

                HStack {
                    TextField("username.eth or 0x0…", text: $presenter.input)
                        .font(.body)
                        .foregroundColor(.w_foreground)

                    if presenter.isClearVisible {
                        Button(action: { presenter.didPressClear() }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .frame(width: 17.0, height: 17.0)
                        })
                    }
                }
                .padding(.horizontal, 16.0)
            }
            .frame(height: 72.0)
            .background(
                RoundedRectangle(cornerRadius: 14.0)
                    .foregroundColor(.w_secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14.0)
                    .stroke(Color.w_tertiaryBackground, lineWidth: 0.5)
            )
            .padding(16.0)

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
