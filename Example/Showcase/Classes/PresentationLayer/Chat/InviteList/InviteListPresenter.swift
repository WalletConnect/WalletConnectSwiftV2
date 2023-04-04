import UIKit
import Combine
import WalletConnectChat

final class InviteListPresenter: ObservableObject {

    private let interactor: InviteListInteractor
    private let router: InviteListRouter
    private let account: Account
    private let inviteType: InviteType
    private var disposeBag = Set<AnyCancellable>()

    var invites: [InviteViewModel] {
        switch inviteType {
        case .received:
            return receivedInviteViewModels
        case .sent:
            return sentInviteViewModels
        }
    }

    @Published private var receivedInvites: [ReceivedInvite] = []
    @Published private var sentInvites: [SentInvite] = []

    private var receivedInviteViewModels: [InviteViewModel] {
        return receivedInvites
            .sorted(by: { $0.timestamp > $1.timestamp })
            .map { InviteViewModel(invite: $0) }
    }

    private var sentInviteViewModels: [InviteViewModel] {
        return sentInvites
            .sorted(by: { $0.timestamp > $1.timestamp })
            .map { InviteViewModel(invite: $0) }
    }

    init(interactor: InviteListInteractor, router: InviteListRouter, account: Account, inviteType: InviteType) {
        defer { setupInitialState() }
        self.interactor = interactor
        self.router = router
        self.account = account
        self.inviteType = inviteType
    }

    func didPressAccept(invite: InviteViewModel) async throws {
        guard let invite = invite.receivedInvite else { return }
        try await interactor.accept(invite: invite)
    }

    func didPressReject(invite: InviteViewModel) async throws {
        guard let invite = invite.receivedInvite else { return }
        try await interactor.reject(invite: invite)
    }
}

// MARK: SceneViewModel

extension InviteListPresenter: SceneViewModel {

    var sceneTitle: String? {
        return inviteType.title
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        return .always
    }
}

// MARK: Privates

private extension InviteListPresenter {

    func setupInitialState() {
        receivedInvites = interactor.getReceivedInvites(account: account)
        sentInvites = interactor.getSentInvites(account: account)

        interactor.receivedInvitesSubscription()
            .sink { [unowned self] receivedInvites in
                self.receivedInvites = receivedInvites
            }.store(in: &disposeBag)

        interactor.sentInvitesSubscription()
            .sink { [unowned self] sentInvites in
                self.sentInvites = sentInvites
            }.store(in: &disposeBag)
    }

    @MainActor
    func dismiss() {
        router.dismiss()
    }
}
