import Foundation

protocol HistoryServiceProtocol {
    
    func getSessionRequest(id: RPCID) -> (request: Request, context: VerifyContext?)?
    
    func removePendingRequest(topic: String)
    
    func getPendingRequests() -> [(request: Request, context: VerifyContext?)]
    
    func getPendingRequestsSortedByTimestamp() -> [(request: Request, context: VerifyContext?)]
}

final class HistoryService: HistoryServiceProtocol {

    private let history: RPCHistory
    private let verifyContextStore: CodableStore<VerifyContext>

    init(
        history: RPCHistory,
        verifyContextStore: CodableStore<VerifyContext>
    ) {
        self.history = history
        self.verifyContextStore = verifyContextStore
    }
    
    func getSessionRequest(id: RPCID) -> (request: Request, context: VerifyContext?)? {
        guard let record = history.get(recordId: id) else { return nil }
        guard let (request, recordId, _) = mapRequestRecord(record) else {
            return nil
        }
        return (request, try? verifyContextStore.get(key: recordId.string))
    }
    
    func removePendingRequest(topic: String) {
        DispatchQueue.global(qos: .background).async { [unowned self] in
            history.deleteAll(forTopic: topic)
        }
    }

    func getPendingRequests() -> [(request: Request, context: VerifyContext?)] {
        getPendingRequestsSortedByTimestamp()
    }

    func getPendingRequestsSortedByTimestamp() -> [(request: Request, context: VerifyContext?)] {
        let requests = history.getPending()
            .compactMap { mapRequestRecord($0) }
            .filter { !$0.0.isExpired() }
            .sorted {
                switch ($0.2, $1.2) {
                case let (date1?, date2?): return date1 < date2 // Both dates are present
                case (nil, _): return false // First date is nil, so it should go last
                case (_, nil): return true  // Second date is nil, so the first one should come first
                }
            }
            .map { (request: $0.0, context: try? verifyContextStore.get(key: $0.1.string)) }

        return requests
    }

    func getPendingExpirableRequestsWithId() -> [(Expirable, RPCID)] {
        let pendingRequests = history.getPending()
        var expirableRpcIds: [(Expirable, RPCID)] = []

        for record in pendingRequests {

            if let requestParams = try? record.request.params?.get(SessionType.RequestParams.self) {
                expirableRpcIds.append((requestParams.request, record.id))
            }
            else if let authRequestParams = try? record.request.params?.get(SessionAuthenticateRequestParams.self) {
                expirableRpcIds.append((authRequestParams, record.id))
            }
        }

        return expirableRpcIds
    }

    func getPendingRequests(topic: String) -> [(request: Request, context: VerifyContext?)] {
        return getPendingRequestsSortedByTimestamp().filter { $0.request.topic == topic }
    }
}

private extension HistoryService {
    func mapRequestRecord(_ record: RPCHistory.Record) -> (Request, RPCID, Date?)? {
        guard let request = try? record.request.params?.get(SessionType.RequestParams.self)
        else { return nil }

        let mappedRequest = Request(
            id: record.id,
            topic: record.topic,
            method: request.request.method,
            params: request.request.params,
            chainId: request.chainId,
            expiryTimestamp: request.request.expiryTimestamp
        )

        return (mappedRequest, record.id, record.timestamp)
    }
}

#if DEBUG
final class MockHistoryService: HistoryServiceProtocol {
    
    var removePendingRequestCalled: (String) -> Void = { _ in }
    
    var pendingRequests: [(request: Request, context: VerifyContext?)] = []

    func removePendingRequest(topic: String) {
        pendingRequests.removeAll(where: { $0.request.topic == topic })
        removePendingRequestCalled(topic)
    }
    
    func getSessionRequest(id: RPCID) -> (request: Request, context: VerifyContext?)? {
        fatalError("Unimplemented")
    }
    
    func getPendingRequests() -> [(request: Request, context: VerifyContext?)] {
        pendingRequests
    }
    
    func getPendingRequestsSortedByTimestamp() -> [(request: Request, context: VerifyContext?)] {
        fatalError("Unimplemented")
    }
}
#endif
