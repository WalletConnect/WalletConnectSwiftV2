import Foundation

final class HistoryService {

    private let history: RPCHistory

    init(history: RPCHistory) {
        self.history = history
    }

    func getPendingRequests() -> [Request] {
        return history.getPending()
            .compactMap { mapRequestRecord($0) }
            .filter { !$0.isExpired() }
    }

    func getPendingRequests(topic: String) -> [Request] {
        return getPendingRequests().filter { $0.topic == topic }
    }

    public func getSessionRequest(id: RPCID) -> Request? {
        guard let record = history.get(recordId: id) else { return nil }
        return mapRequestRecord(record)
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
