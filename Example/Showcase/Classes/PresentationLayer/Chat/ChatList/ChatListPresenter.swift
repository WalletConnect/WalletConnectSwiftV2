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
            .sorted(by: { $0.timestamp < $1.timestamp })
            .map { InviteViewModel(invite: $0) }
    }

    init(account: Account, interactor: ChatListInteractor, router: ChatListRouter) {
        self.account = account
        self.interactor = interactor
        self.router = router
    }

    func setupInitialState() {
        Task(priority: .userInitiated) {
            await setupThreads()
        }
        Task(priority: .userInitiated) {
            await setupInvites()
        }
    }

    var requestsCount: String {
        return String(receivedInvites.count)
    }

    var showRequests: Bool {
        return !receivedInvites.isEmpty
    }

    func didPressThread(_ thread: ThreadViewModel) {
        router.presentChat(thread: thread.thread)
    }

    func didPressChatRequests() {
        router.presentInviteList(account: account)
    }

    func didLogoutPress() {
        interactor.logout()
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

    @MainActor
    func setupThreads() async {
        threads = interactor.getThreads()

        for await newThreads in interactor.threadsSubscription() {
            threads = newThreads
        }
    }

    @MainActor
    func setupInvites() async {
        receivedInvites = interactor.getInvites()

        for await invites in interactor.receivedInvitesSubscription() {
            receivedInvites = invites
        }
    }

    @objc func presentInvite() {
        router.presentInvite(account: account)
    }
}
