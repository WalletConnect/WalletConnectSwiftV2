import Combine
import Foundation

class SessionRequestsProvider {
    private let historyService: HistoryService
    private var sessionRequestPublisherSubject = PassthroughSubject<(request: Request, context: VerifyContext?), Never>()
    private var cancellables = Set<AnyCancellable>()
    private var lastEmitDate: Date?
    private var emitRequestSubject = PassthroughSubject<Void, Never>()

    public var sessionRequestPublisher: AnyPublisher<(request: Request, context: VerifyContext?), Never> {
        sessionRequestPublisherSubject.eraseToAnyPublisher()
    }

    init(historyService: HistoryService) {
        self.historyService = historyService
        setupEmitRequestHandling()
    }

    private func setupEmitRequestHandling() {
        emitRequestSubject
            .sink { [weak self] _ in
                guard let self = self else { return }
                let now = Date()
                if let lastEmitDate = self.lastEmitDate, now.timeIntervalSince(lastEmitDate) < 1 {
                    // If the last emit was less than 1 second ago, ignore this request.
                    return
                }

                // Update the last emit time to now.
                self.lastEmitDate = now

                // Fetch the oldest request and emit it.
                if let oldestRequest = self.historyService.getPendingRequestsSortedByTimestamp().first {
                    self.sessionRequestPublisherSubject.send(oldestRequest)
                }
            }
            .store(in: &cancellables)
    }

    func emitRequestIfPending() {
        emitRequestSubject.send(())
    }
}
