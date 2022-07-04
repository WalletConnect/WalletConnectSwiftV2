import UIKit
import Combine

final class ChatListPresenter: ObservableObject {

    private let interactor: ChatListInteractor
    private let router: ChatListRouter
    private var disposeBag = Set<AnyCancellable>()

    init(interactor: ChatListInteractor, router: ChatListRouter) {
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func setupInitialState() async {

    }

    func didPressChatRequests() {
        router.presentInviteList()
    }
}

// MARK: SceneViewModel

extension ChatListPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Chat"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }

    var rightBarButtonItem: UIBarButtonItem? {
        return UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(presentInvite)
        )
    }
}

// MARK: Privates

private extension ChatListPresenter {

    @objc func presentInvite() {
        router.presentInvite()
    }
}
