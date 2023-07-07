import SwiftUI
import WalletConnectModal

struct ImportView: View {

    @EnvironmentObject var presenter: ImportPresenter

    var body: some View {
        VStack(spacing: 8.0) {
            Image("profile_icon")
                .resizable()
                .frame(width: 128, height: 128)
                .padding(.top, 24.0)

            TextFieldView(title: "Private key", placeholder: "4dc0055d1831…", input: $presenter.input)

            Spacer()

            VStack {
                
                BrandButton(title: "WalletConnectModal WIP") {
                    try await presenter.didPressWalletConnectModal()
                }
                
                BrandButton(title: "Ok, done" ) {
                    try await presenter.didPressImport()
                }
            }
            .padding(16.0)

            PlainButton {
                try await presenter.didPressRandom()
            } label: {
                Text("Create new account")
                    .foregroundColor(.white)
            }
            .padding(.bottom, 16)
        }
    }
}

#if DEBUG
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView()
    }
}
#endif
