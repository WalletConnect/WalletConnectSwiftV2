import Foundation

actor AppPairService {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let pairingStorage: WCPairingStorage
    private var registeredMethods: [String] = []

    init(networkingInteractor: NetworkInteracting, kms: KeyManagementServiceProtocol, pairingStorage: WCPairingStorage) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.pairingStorage = pairingStorage
    }

    public func register(supportedMethods: [String]) async {
        registeredMethods = supportedMethods
    }

    func create() async throws -> WalletConnectURI {
        let topic = String.generateTopic()
        try await networkingInteractor.subscribe(topic: topic)
        let symKey = try! kms.createSymmetricKey(topic)
        let pairing = WCPairing(topic: topic)
        let uri = WalletConnectURI(topic: topic, symKey: symKey.hexRepresentation, relay: pairing.relay, methods: registeredMethods)
        pairingStorage.setPairing(pairing)
        return uri
    }
}
