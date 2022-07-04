import UIKit
import Combine

final class ChatPresenter: ObservableObject {

    private let interactor: ChatInteractor
    private let router: ChatRouter
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: ChatInteractor, router: ChatRouter) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
    }
}

// MARK: SceneViewModel

extension ChatPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Chat"
    }
}

// MARK: Privates

private extension ChatPresenter {

    func setupInitialState() {

    }
}
