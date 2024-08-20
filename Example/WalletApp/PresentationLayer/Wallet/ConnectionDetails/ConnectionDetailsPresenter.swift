import UIKit
import Combine

import Web3Wallet

final class ConnectionDetailsPresenter: ObservableObject {
    private let router: ConnectionDetailsRouter
    
    let session: Session
    
    private var disposeBag = Set<AnyCancellable>()

    init(
        router: ConnectionDetailsRouter,
        session: Session
    ) {
        self.router = router
        self.session = session
    }

    func onDelete() {
        Task {
            do {
                ActivityIndicatorManager.shared.start()
                try await Web3Wallet.instance.disconnect(topic: session.topic)
                ActivityIndicatorManager.shared.stop()
                DispatchQueue.main.async {
                    self.router.dismiss()
                }
            } catch {
                ActivityIndicatorManager.shared.stop()
                print(error)
            }
        }
    }


    func accountReferences(namespace: String) -> [String] {
        session.namespaces[namespace]?.accounts.map { "\($0.namespace):\(($0.reference))" } ?? []
    }

    func changeForMainnet() {
        Task {
            do {
                ActivityIndicatorManager.shared.start()

                try await Web3Wallet.instance.emit(topic: session.topic, event: Session.Event(name: "chainChanged", data: AnyCodable("1")), chainId: Blockchain("eip155:1")!)

                ActivityIndicatorManager.shared.stop()
            } catch {
                ActivityIndicatorManager.shared.stop()
                print(error)
            }
        }
    }
}

// MARK: - Private functions
private extension ConnectionDetailsPresenter {

}

// MARK: - SceneViewModel
extension ConnectionDetailsPresenter: SceneViewModel {

}
