import SwiftUI

struct WalletView: View {

    @EnvironmentObject var presenter: WalletPresenter

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { presenter.didPastePairingURI() }, label: {
                HStack(spacing: 8.0) {
                    Text("Paste pairing URI")
                        .foregroundColor(.w_foreground)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.trailing, 8.0)
            })
            .frame(width: 200, height: 44)
            .background(
                Capsule()
                    .foregroundColor(.w_greenForground)
            )

            Button(action: { presenter.didScanPairingURI() }, label: {
                HStack(spacing: 8.0) {
                    Text("Scan pairing URI")
                        .foregroundColor(.w_foreground)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.trailing, 8.0)
            })
            .frame(width: 200, height: 44)
            .background(
                Capsule()
                    .foregroundColor(.w_purpleForeground)
            )
        }
    }
}

#if DEBUG
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
    }
}
#endif
