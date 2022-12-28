import Foundation
import WalletConnectChat

final class ChatClientProxy {

    private let client: ChatClient

    var onResponse: ((WebViewResponse) -> Void)?

    init(client: ChatClient) {
        self.client = client
    }

    func execute(request: WebViewRequest) {
        switch request {
        case .getInvites(let account):
            let invites = client.getInvites(account: Account(account)!)
            onResponse?(.getInvites(invites: invites))
        }
    }
}
