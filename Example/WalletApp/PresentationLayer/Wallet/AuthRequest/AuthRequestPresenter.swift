import UIKit
import Combine

import Web3Wallet
import WalletConnectRouter

final class AuthRequestPresenter: ObservableObject {
    private let router: AuthRequestRouter

    let importAccount: ImportAccount
    let request: AuthenticationRequest
    let validationStatus: VerifyContext.ValidationStatus?
    
    var messages: [(String, String)] {
        return buildFormattedMessages(request: request, account: importAccount.account)
    }

    func buildFormattedMessages(request: AuthenticationRequest, account: Account) -> [(String, String)] {
        request.payload.chains.enumerated().compactMap { index, chain in
            guard let blockchain = Blockchain(chain),
                  let chainAccount = Account(blockchain: blockchain, address: account.address) else {
                return nil
            }
            guard let formattedMessage = try? Web3Wallet.instance.formatAuthMessage(payload: request.payload, account: chainAccount) else {
                return nil
            }
            let messagePrefix = "Message \(index + 1):"
            return (messagePrefix, formattedMessage)
        }
    }

    @Published var showSignedSheet = false
    
    private var disposeBag = Set<AnyCancellable>()

    private let messageSigner: MessageSigner

    init(
        importAccount: ImportAccount,
        router: AuthRequestRouter,
        request: AuthenticationRequest,
        context: VerifyContext?,
        messageSigner: MessageSigner
    ) {
        defer { setupInitialState() }
        self.router = router
        self.importAccount = importAccount
        self.request = request
        self.validationStatus = context?.validation
        self.messageSigner = messageSigner
    }

    @MainActor
    func approve() async {
        do {

            let auths = try buildAuthObjects()

            _ = try await Web3Wallet.instance.approveSessionAuthenticate(requestId: request.id, auths: auths)

            /* Redirect */
            if let uri = request.requester.redirect?.native {
                WalletConnectRouter.goBack(uri: uri)
                router.dismiss()
            } else {
                showSignedSheet.toggle()
            }

        } catch {
            AlertPresenter.present(message: error.localizedDescription, type: .error)
        }
    }

    @MainActor
    func reject() async  {
        
        do {
            try await Web3Wallet.instance.rejectSession(requestId: request.id)

            /* Redirect */
            if let uri = request.requester.redirect?.native {
                WalletConnectRouter.goBack(uri: uri)
            }
            router.dismiss()
        } catch {
            AlertPresenter.present(message: error.localizedDescription, type: .error)
        }
    }
    
    func onSignedSheetDismiss() {
        router.dismiss()
    }

    private func buildAuthObjects() throws -> [AuthObject] {
        var auths = [AuthObject]()

        try request.payload.chains.forEach { chain in

            let account = Account(blockchain: Blockchain(chain)!, address: importAccount.account.address)!

            let supportedAuthPayload = try Web3Wallet.instance.buildAuthPayload(payload: request.payload, supportedEVMChains: [Blockchain("eip155:1")!, Blockchain("eip155:137")!], supportedMethods: ["eth_signTransaction", "personal_sign"])

            let SIWEmessages = try Web3Wallet.instance.formatAuthMessage(payload: supportedAuthPayload, account: account)

            let signature = try messageSigner.sign(
                message: SIWEmessages,
                privateKey: Data(hex: importAccount.privateKey),
                type: .eip191)

            let auth = try Web3Wallet.instance.buildSignedAuthObject(authPayload: supportedAuthPayload, signature: signature, account: account)

            auths.append(auth)
        }
        return auths
    }

    func dismiss() {
        router.dismiss()
    }
}

// MARK: - Private functions
private extension AuthRequestPresenter {
    func setupInitialState() {
        Web3Wallet.instance.requestExpirationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requestId in
                guard let self = self else { return }
                if requestId == request.id {
                    dismiss()
                }
            }.store(in: &disposeBag)
    }
}

// MARK: - SceneViewModel
extension AuthRequestPresenter: SceneViewModel {

}
