import Combine
import Foundation

class SessionRequestsProvider {
    private let historyService: HistoryService
    private var sessionRequestPublisherSubject = PassthroughSubject<(request: Request, context: VerifyContext?), Never>()
    private var lastEmitTime: Date?
    private let debounceInterval: TimeInterval = 1

    public var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        sessionRequestPublisherSubject.eraseToAnyPublisher()
    }

    init(historyService: HistoryService) {
        self.historyService = historyService
    }

    func emitRequestIfPending() {
        let now = Date()
        if let lastEmitTime = lastEmitTime, now.timeIntervalSince(lastEmitTime) < debounceInterval {
            return
        }

        self.lastEmitTime = now

        if let oldestRequest = self.historyService.getPendingRequestsSortedByTimestamp().first {
            self.sessionRequestPublisherSubject.send(oldestRequest)
        }
    }
}
