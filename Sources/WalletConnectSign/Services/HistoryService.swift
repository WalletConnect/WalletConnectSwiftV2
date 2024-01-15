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
        guard let (request, recordId) = mapRequestRecord(record) else {
            return nil
        }
        return (request, try? verifyContextStore.get(key: recordId.string))
    }

    func getPendingRequests() -> [(request: Request, context: VerifyContext?)] {
        let requests = history.getPending()
            .compactMap { mapRequestRecord($0) }
            .filter { !$0.0.isExpired() } // Note the change here to access the Request part of the tuple
        return requests.map { (request: $0.0, context: try? verifyContextStore.get(key: $0.1.string)) }
    }


    func getPendingRequestsWithRecordId() -> [(request: Request, recordId: RPCID)] {
        history.getPending()
            .compactMap { mapRequestRecord($0) }
    }

    func getPendingRequests(topic: String) -> [(request: Request, context: VerifyContext?)] {
        return getPendingRequests().filter { $0.request.topic == topic }
    }
}

private extension HistoryService {
    func mapRequestRecord(_ record: RPCHistory.Record) -> (Request, RPCID)? {
        guard let request = try? record.request.params?.get(SessionType.RequestParams.self)
        else { return nil }

        let mappedRequest = Request(
            id: record.id,
            topic: record.topic,
            method: request.request.method,
            params: request.request.params,
            chainId: request.chainId,
            expiry: request.request.expiry
        )

        return (mappedRequest, record.id)
    }
}
