import Foundation
@testable import WalletConnectSign
@testable import Web3Wallet
import Combine

final class Web3ClientDelegate {
    var client: Web3WalletClient
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

    init(client: Web3WalletClient) {
        self.client = client
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        client.signClient.sessionSettlePublisher.sink { session in
            self.onSessionSettled?(session)
        }.store(in: &publishers)

        client.signClient.socketConnectionStatusPublisher.sink { _ in
            self.onConnected?()
        }.store(in: &publishers)

        client.sessionProposalPublisher.sink { proposal in
            self.onSessionProposal?(proposal)
        }.store(in: &publishers)

        client.sessionRequestPublisher.sink { request in
            self.onSessionRequest?(request)
        }.store(in: &publishers)

        client.signClient.sessionResponsePublisher.sink { response in
            self.onSessionResponse?(response)
        }.store(in: &publishers)

        client.signClient.sessionRejectionPublisher.sink { (proposal, reason) in
            self.onSessionRejected?(proposal, reason)
        }.store(in: &publishers)

        client.signClient.sessionDeletePublisher.sink { _ in
            self.onSessionDelete?()
        }.store(in: &publishers)

        client.signClient.sessionUpdatePublisher.sink { (topic, namespaces) in
            self.onSessionUpdateNamespaces?(topic, namespaces)
        }.store(in: &publishers)

        client.signClient.sessionEventPublisher.sink { (event, topic, _) in
            self.onEventReceived?(event, topic)
        }.store(in: &publishers)

        client.signClient.sessionExtendPublisher.sink { (topic, date) in
            self.onSessionExtend?(topic, date)
        }.store(in: &publishers)

        client.signClient.pingResponsePublisher.sink { topic in
            self.onPing?(topic)
        }.store(in: &publishers)
    }
}
