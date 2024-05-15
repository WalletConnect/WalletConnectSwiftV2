
import Foundation

protocol InvalidRequestsSanitiserProtocol {
    
    func removeInvalidSessionRequests(validSessionTopics: Set<String>)
    
    func removeSessionRequestsWith(topic: String)
}

final class InvalidRequestsSanitiser: InvalidRequestsSanitiserProtocol {
    private let historyService: HistoryServiceProtocol
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
    
    func removeSessionRequestsWith(topic: String) {
        let pendingRequestTopics = historyService
            .getPendingRequests(topic: topic)
            .map(\.request)
            .map(\.topic)
        
        history.deleteAll(forTopics: pendingRequestTopics)
    }
}

#if DEBUG
final class MockInvalidRequestsSanitiser: InvalidRequestsSanitiserProtocol {
    var removedTopics: [String] = []
    
    func removeInvalidSessionRequests(validSessionTopics: Set<String>) {
        removedTopics = removedTopics + Array(validSessionTopics)
    }

    func removeSessionRequestsWith(topic: String) {
        removedTopics.append(topic)
    }
}
#endif
