import UIKit
import Combine
import WalletConnectUtils

final class ChatListPresenter: ObservableObject {

    private let interactor: ChatListInteractor
    private let router: ChatListRouter
    private let account: Account
    private var disposeBag = Set<AnyCancellable>()

    @Published var threads: [ThreadViewModel] = []
    @Published var invites: [InviteViewModel] = []

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
        return String(invites.count)
    }

    var showRequests: Bool {
        return !invites.isEmpty
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
        await loadThreads()

        for await _ in interactor.threadsSubscription() {
            await loadThreads()
        }
    }

    @MainActor
    func setupInvites() async {
        await loadInvites()

        for await _ in interactor.invitesSubscription() {
            await loadInvites()
        }
    }

    @MainActor
    func loadThreads() async {
        let threads = await interactor.getThreads()
        self.threads = threads
            .filter { $0.selfAccount == account }
            .sorted(by: { $0.topic < $1.topic })
            .map { ThreadViewModel(thread: $0) }
    }

    @MainActor
    func loadInvites() async {
        let invites = await interactor.getInvites(account: account)
        self.invites = invites.sorted(by: { $0.publicKey < $1.publicKey })
            .map { InviteViewModel(invite: $0) }
    }

    @objc func presentInvite() {
        router.presentInvite(account: account)
    }
}
