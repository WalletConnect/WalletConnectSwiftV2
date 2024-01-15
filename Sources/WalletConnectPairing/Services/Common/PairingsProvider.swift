import Foundation

class PairingsProvider {
    enum Errors: Error {
        case noPairingMatchingTopic
    }
    private let pairingStorage: WCPairingStorage

    public init(pairingStorage: WCPairingStorage) {
        self.pairingStorage = pairingStorage
    }

    func getPairings() -> [Pairing] {
        pairingStorage.getAll()
            .map {Pairing($0)}
    }

    func getPairing(for topic: String) throws -> Pairing {
        guard let pairing = pairingStorage.getPairing(forTopic: topic) else {
            throw Errors.noPairingMatchingTopic
        }
        return Pairing(pairing)
    }
}

import Combine
import Foundation

class PairingStateProvider {
    private let pairingStorage: WCPairingStorage
    private var pairingStatePublisherSubject = PassthroughSubject<Bool, Never>()
    private var checkTimer: Timer?

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
        let pairingStateActive = !pairingStorage.getAll().allSatisfy { $0.active || $0.requestReceived}
        pairingStatePublisherSubject.send(pairingStateActive)
    }
}
