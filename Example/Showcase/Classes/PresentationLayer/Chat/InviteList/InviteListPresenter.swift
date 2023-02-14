import UIKit
import Combine
import WalletConnectChat

final class InviteListPresenter: ObservableObject {

    private let interactor: InviteListInteractor
    private let router: InviteListRouter
    private let account: Account
    private var disposeBag = Set<AnyCancellable>()

    @Published private var receivedInvites: [ReceivedInvite] = []

    var invites: [InviteViewModel] {
        return receivedInvites
            .sorted(by: { $0.timestamp > $1.timestamp })
            .map { InviteViewModel(invite: $0) }
    }

    init(interactor: InviteListInteractor, router: InviteListRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

    @MainActor
    func setupInitialState() async {
        receivedInvites = interactor.getReceivedInvites()

        for await invites in interactor.invitesReceivedSubscription() {
            receivedInvites = invites
        }
    }

    func didPressAccept(invite: InviteViewModel) {
        Task(priority: .userInitiated) {
            await interactor.accept(invite: invite.invite)
            await dismiss()
        }
    }

    func didPressReject(invite: InviteViewModel) {
        Task(priority: .userInitiated) {
            await interactor.reject(invite: invite.invite)
            await dismiss()
        }
    }
}

// MARK: SceneViewModel

extension InviteListPresenter: SceneViewModel {

    var sceneTitle: String? {
        return "Chat Requests"
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension InviteListPresenter {

    @MainActor
    func dismiss() {
        router.dismiss()
    }
}
