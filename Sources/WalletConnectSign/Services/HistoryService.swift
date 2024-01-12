import Foundation

final class HistoryService {

    private let history: RPCHistory
    private let verifyContextStore: CodableStore<VerifyContext>

    init(
        history: RPCHistory,
        verifyContextStore: CodableStore<VerifyContext>
    ) {
        self.history = history
        self.verifyContextStore = verifyContextStore
    }

    public func getSessionRequest(id: RPCID) -> (request: Request, context: VerifyContext?)? {
        guard let record = history.get(recordId: id) else { return nil }
        guard let request = mapRequestRecord(record) else {
            return nil
        }
        return (request, try? verifyContextStore.get(key: request.id.string))
    }
    
    func getPendingRequests() -> [(request: Request, context: VerifyContext?)] {
        let requests = history.getPending()
            .compactMap { mapRequestRecord($0) }
            .filter { !$0.isExpired() }
        return requests.map { ($0, try? verifyContextStore.get(key: $0.id.string)) }
    }

    func getPendingRequests(topic: String) -> [(request: Request, context: VerifyContext?)] {
        return getPendingRequests().filter { $0.request.topic == topic }
    }
}

private extension HistoryService {
    func mapRequestRecord(_ record: RPCHistory.Record) -> Request? {
        guard let request = try? record.request.params?.get(SessionType.RequestParams.self)
        else { return nil }

        return Request(
            id: record.id,
            topic: record.topic,
            method: request.request.method,
            params: request.request.params,
            chainId: request.chainId,
            expiry: request.request.expiry
        )
    }
}
