import Foundation
@testable import WalletConnectSign
import Combine

class ClientDelegate {

    var client: SignClient
    var onSessionSettled: ((Session) -> Void)?
    var onConnected: (() -> Void)?
    var onSessionProposal: ((Session.Proposal) -> Void)?
    var onSessionRequest: ((Request) -> Void)?
    var onSessionResponse: ((Response) -> Void)?
    var onSessionRejected: ((Session.Proposal, Reason) -> Void)?
    var onSessionDelete: (() -> Void)?
    var onSessionUpdateNamespaces: ((String, [String: SessionNamespace]) -> Void)?
    var onSessionExtend: ((String, Date) -> Void)?
    var onPing: ((String) -> Void)?
    var onEventReceived: ((Session.Event, String) -> Void)?

    private var publishers = Set<AnyCancellable>()

    init(client: SignClient) {
        self.client = client
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        client.sessionSettlePublisher.sink { session in
            self.onSessionSettled?(session)
        }.store(in: &publishers)

        client.socketConnectionStatusPublisher.sink { _ in
            self.onConnected?()
        }.store(in: &publishers)

        client.sessionProposalPublisher.sink { result in
            self.onSessionProposal?(result.proposal)
        }.store(in: &publishers)

        client.sessionRequestPublisher.sink { result in
            self.onSessionRequest?(result.request)
        }.store(in: &publishers)

        client.sessionResponsePublisher.sink { response in
            self.onSessionResponse?(response)
        }.store(in: &publishers)

        client.sessionRejectionPublisher.sink { (proposal, reason) in
            self.onSessionRejected?(proposal, reason)
        }.store(in: &publishers)

        client.sessionDeletePublisher.sink { _ in
            self.onSessionDelete?()
        }.store(in: &publishers)

        client.sessionUpdatePublisher.sink { (topic, namespaces) in
            self.onSessionUpdateNamespaces?(topic, namespaces)
        }.store(in: &publishers)

        client.sessionEventPublisher.sink { (event, topic, _) in
            self.onEventReceived?(event, topic)
        }.store(in: &publishers)

        client.sessionExtendPublisher.sink { (topic, date) in
            self.onSessionExtend?(topic, date)
        }.store(in: &publishers)

        client.pingResponsePublisher.sink { topic in
            self.onPing?(topic)
        }.store(in: &publishers)
    }
}
