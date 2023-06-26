@testable import WalletConnectPush
import Foundation

class Publisher {

    var logger: ConsoleLogging

    init(logger: ConsoleLogging = ConsoleLogger(suffix: "🐙", loggingLevel: .debug)) {
        self.logger = logger
    }

    func notify(topic: String, account: Account, message: PushMessage) async throws {
        logger.debug("cast host has been set for: \(InputConfig.castHost)")
        let url = URL(string: "https://\(InputConfig.castHost)/\(InputConfig.gmDappProjectId)/notify")!
        var request = URLRequest(url: url)
        let notifyRequestPayload = NotifyRequest(notification: message, accounts: [account])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let payload = try encoder.encode(notifyRequestPayload)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Notify error") }
    }
}

struct NotifyRequest: Codable {
    let notification: PushMessage
    let accounts: [Account]
}
