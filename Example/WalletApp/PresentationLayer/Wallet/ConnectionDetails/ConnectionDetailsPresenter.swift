import UIKit
import Combine

import Auth
import Web3Wallet

final class ConnectionDetailsPresenter: ObservableObject {
    private let interactor: ConnectionDetailsInteractor
    private let router: ConnectionDetailsRouter
    
    let session: Session
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: ConnectionDetailsInteractor,
        router: ConnectionDetailsRouter,
        session: Session
    ) {
        self.interactor = interactor
        self.router = router
        self.session = session
    }

    func onDelete() {
        Task {
            do {
                try await interactor.disconnectSession(session: session)
                DispatchQueue.main.async {
                    self.router.dismiss()
                }
            } catch {
                print(error)
            }
        }
    }
    
    func accountReference(namespace: String) -> String {
        "\(session.namespaces[namespace]?.accounts.first?.namespace ?? ""):\((session.namespaces[namespace]?.accounts.first?.reference ?? ""))"
    }
}

// MARK: - Private functions
private extension ConnectionDetailsPresenter {

}

// MARK: - SceneViewModel
extension ConnectionDetailsPresenter: SceneViewModel {

}
