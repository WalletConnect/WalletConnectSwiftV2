
import Foundation
import WalletConnectSign

final class SessionResponsePresenter: ObservableObject, SceneViewModel {

    private let router: SessionResponseRouter
    let response: Response

    init(
        router: SessionResponseRouter,
        sessionResponse: Response
    ) {
        self.router = router
        self.response = sessionResponse
    }
}
