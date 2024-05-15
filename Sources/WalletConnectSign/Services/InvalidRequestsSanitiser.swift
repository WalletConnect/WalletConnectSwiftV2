
import Foundation

class InvalidRequestsSanitiser {
    let historyService: HistoryServiceProtocol
    private let history: RPCHistoryProtocol

    init(historyService: HistoryServiceProtocol, history: RPCHistoryProtocol) {
        self.historyService = historyService
        self.history = history
    }

    func removeInvalidSessionRequests(validSessionTopics: Set<String>) {
        let pendingRequests = historyService.getPendingRequests()
        let invalidTopics = Set(pendingRequests.map { $0.request.topic }).subtracting(validSessionTopics)
        if !invalidTopics.isEmpty {
            history.deleteAll(forTopics: Array(invalidTopics))
        }
    }
}
