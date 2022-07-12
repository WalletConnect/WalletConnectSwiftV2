import UIKit
import Combine
import Chat

final class InviteListPresenter: ObservableObject {

    private let interactor: InviteListInteractor
    private let router: InviteListRouter
    private var disposeBag = Set<AnyCancellable>()

    @Published var invites: [InviteViewModel] = []

    init(interactor: InviteListInteractor, router: InviteListRouter) {
        self.interactor = interactor
        self.router = router
    }

    @MainActor
    func setupInitialState() async {
        await loadInvites()

        for await _ in interactor.invitesSubscription() {
            await loadInvites()
        }
    }

    func didPressAccept(invite: InviteViewModel) {
        Task {
            await interactor.accept(invite: invite.invite)
        }
    }

    func didPressReject(invite: InviteViewModel) {
        Task {
            await interactor.reject(invite: invite.invite)
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

    func loadInvites() async {
        let invites = await interactor.getInvites()
        self.invites = invites.sorted(by: { $0.publicKey < $1.publicKey })
            .map { InviteViewModel(invite: $0) }
    }
}
