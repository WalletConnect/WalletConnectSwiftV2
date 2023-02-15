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
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.account = account
    }

    func didPressAccept(invite: InviteViewModel) async throws {
        try await interactor.accept(invite: invite.invite)
    }

    func didPressReject(invite: InviteViewModel) async throws {
        try await interactor.reject(invite: invite.invite)
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

    func setupInitialState() {
        receivedInvites = interactor.getReceivedInvites()

        interactor.invitesReceivedSubscription()
            .sink { [unowned self] receivedInvites in
                self.receivedInvites = receivedInvites
            }.store(in: &disposeBag)
    }

    @MainActor
    func dismiss() {
        router.dismiss()
    }
}
