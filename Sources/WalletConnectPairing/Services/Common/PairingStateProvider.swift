import Combine
import Foundation

class PairingStateProvider {
    private let pairingStorage: WCPairingStorage
    private var pairingStatePublisherSubject = PassthroughSubject<Bool, Never>()
    private var checkTimer: Timer?
    private var lastPairingState: Bool?

    public var pairingStatePublisher: AnyPublisher<Bool, Never> {
        pairingStatePublisherSubject.eraseToAnyPublisher()
    }

    public init(pairingStorage: WCPairingStorage) {
        self.pairingStorage = pairingStorage
        setupPairingStateCheckTimer()
    }

    private func setupPairingStateCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            checkPairingState()
        }
    }

    private func checkPairingState() {
        let pairingStateActive = !pairingStorage.getAll().allSatisfy { $0.requestReceived }

        if lastPairingState != pairingStateActive {
            pairingStatePublisherSubject.send(pairingStateActive)
            lastPairingState = pairingStateActive
        }
    }
}
