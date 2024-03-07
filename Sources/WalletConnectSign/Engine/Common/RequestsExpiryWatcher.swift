
import Foundation
import Combine

class RequestsExpiryWatcher {

    private let requestExpirationPublisherSubject: PassthroughSubject<RPCID, Never> = .init()
    private let rpcHistory: RPCHistory
    private let historyService: HistoryService

    var requestExpirationPublisher: AnyPublisher<RPCID, Never> {
        return requestExpirationPublisherSubject.eraseToAnyPublisher()
    }

    private var checkTimer: Timer?

    internal init(
        proposalPayloadsStore: CodableStore<RequestSubscriptionPayload<SessionType.ProposeParams>>,
        rpcHistory: RPCHistory,
        historyService: HistoryService
    ) {
        self.rpcHistory = rpcHistory
        self.historyService = historyService
        setUpExpiryCheckTimer()
    }

    func setUpExpiryCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [unowned self] _ in
            checkForRequestExpiry()
        }
    }

    func checkForRequestExpiry() {
        let requests = historyService.getPendingExpirableRequestsWithId()
        requests.forEach { (request: Expirable, recordId: RPCID) in
            guard request.isExpired() else { return }
            requestExpirationPublisherSubject.send(recordId)
            rpcHistory.delete(id: recordId)
        }
    }

}
