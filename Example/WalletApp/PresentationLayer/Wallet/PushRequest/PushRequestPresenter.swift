import UIKit
import Combine
import WalletConnectPush

final class PushRequestPresenter: ObservableObject {
    private let interactor: PushRequestInteractor
    private let router: PushRequestRouter

    let pushRequest: PushRequest

    var message: String {
        return String(describing: pushRequest.account)
    }

    private var disposeBag = Set<AnyCancellable>()

    init(
        interactor: PushRequestInteractor,
        router: PushRequestRouter,
        pushRequest: PushRequest
    ) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.pushRequest = pushRequest
    }

    @MainActor
    func onApprove() async throws {
        try await interactor.approve(pushRequest: pushRequest)
        router.dismiss()
    }

    @MainActor
    func onReject() async throws {
        try await interactor.reject(pushRequest: pushRequest)
        router.dismiss()
    }
}

// MARK: - Private functions
private extension PushRequestPresenter {
    func setupInitialState() {

    }
}

// MARK: - SceneViewModel
extension PushRequestPresenter: SceneViewModel {

}
