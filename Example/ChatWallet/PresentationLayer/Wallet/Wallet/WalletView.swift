import SwiftUI

struct WalletView: View {
    let interactor: WalletInteractorProtocol
    @ObservedObject var presenter: WalletPresenter

    var body: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await interactor.pastePairingUri()
                }
            } label: {
                HStack(spacing: 8.0) {
                    Text(presenter.pastPairingUriText)
                        .foregroundColor(.w_foreground)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.trailing, 8.0)
            }
            .frame(width: 200, height: 44)
            .background(
                Capsule()
                    .foregroundColor(.w_greenForground)
            )

            Button {
                interactor.scanPairingUri()
            } label: {
                HStack(spacing: 8.0) {
                    Text(presenter.scanPairingUriText)
                        .foregroundColor(.w_foreground)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.trailing, 8.0)
            }
            .frame(width: 200, height: 44)
            .background(
                Capsule()
                    .foregroundColor(.w_purpleForeground)
            )
        }
        .onAppear {
            interactor.onAppear()
        }
    }
}

#if DEBUG
final class WalletInteractorMock: WalletInteractorProtocol {
    func onAppear() {}
    func pastePairingUri() async {}
    func scanPairingUri() {}
}

struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        let presenter = WalletPresenter()
        WalletView(
            interactor: WalletInteractorMock(),
            presenter: presenter
        )
    }
}
#endif
