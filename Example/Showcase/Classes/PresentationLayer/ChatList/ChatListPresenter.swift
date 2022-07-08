import UIKit
import Combine

final class ChatListPresenter: ObservableObject {

    private let interactor: ChatListInteractor
    private let router: ChatListRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var threads: [ThreadViewModel] = []

    init(interactor: ChatListInteractor, router: ChatListRouter) {
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func setupInitialState() async {
        await loadThreads()

        for await _ in interactor.threadsSubscription() {
            await loadThreads()
        }
    }

    func didPressThread(_ thread: ThreadViewModel) {
        router.presentChat(thread: thread.thread)
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

    func loadThreads() async {
        let threads = await interactor.getThreads()
        self.threads = threads.sorted(by: { $0.topic < $1.topic })
            .map { ThreadViewModel(thread: $0) }
    }

    @objc func presentInvite() {
        router.presentInvite()
    }
}
