
import Foundation

class PushMessageSender {
    private let networkingInteractor: NetworkInteracting
    private let kms: KeyManagementServiceProtocol
    private let logger: ConsoleLogging

    init(networkingInteractor: NetworkInteracting,
         kms: KeyManagementServiceProtocol,
         logger: ConsoleLogging) {
        self.networkingInteractor = networkingInteractor
        self.kms = kms
        self.logger = logger
    }

    func request(topic: String, message: PushMessage) async throws {
        logger.debug("PushMessageSender: Sending Push Message")
        let protocolMethod = PushMessageProtocolMethod()
        let request = RPCRequest(method: protocolMethod.method, params: message)
        try await networkingInteractor.request(request, topic: topic, protocolMethod: protocolMethod)
    }
}
