import UIKit
import Combine
import WalletConnectChat

final class ChatListPresenter: ObservableObject {

    private let interactor: ChatListInteractor
    private let router: ChatListRouter
    private let account: Account
    private var disposeBag = Set<AnyCancellable>()

    @Published private var threads: [WalletConnectChat.Thread] = []
    @Published private var receivedInvites: [ReceivedInvite] = []

    var threadViewModels: [ThreadViewModel] {
        return threads
            .sorted(by: { $0.topic < $1.topic })
            .map { ThreadViewModel(thread: $0) }
    }

    var inviteViewModels: [InviteViewModel] {
        return receivedInvites
            .filter { $0.status == .pending }
            .sorted(by: { $0.timestamp < $1.timestamp })
            .map { InviteViewModel(invite: $0) }
    }

    init(account: Account, interactor: ChatListInteractor, router: ChatListRouter) {
        defer { setupInitialState() }
        self.account = account
        self.interactor = interactor
        self.router = router
    }

    var requestsCount: String {
        return String(inviteViewModels.count)
    }

    var showRequests: Bool {
        return !inviteViewModels.isEmpty
    }

    func didPressThread(_ thread: ThreadViewModel) {
        router.presentChat(thread: thread.thread)
    }

    func didPressChatRequests() {
        router.presentInviteList(account: account)
    }

    @MainActor
    func didLogoutPress() async throws {
        try await interactor.logout()
        router.presentWelcome()
    }

    func didPressNewChat() {
        presentInvite()
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

    func setupInitialState() {
        threads = interactor.getThreads()
        receivedInvites = interactor.getInvites()

        interactor.threadsSubscription()
            .sink { [unowned self] threads in
                self.threads = threads
            }.store(in: &disposeBag)

        interactor.receivedInvitesSubscription()
            .sink { [unowned self] receivedInvites in
                self.receivedInvites = receivedInvites
            }.store(in: &disposeBag)
    }

    @objc func presentInvite() {
        router.presentInvite(account: account)
    }
}
