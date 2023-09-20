@testable import WalletConnectNotify
import Foundation

class Publisher {
    func notify(topic: String, account: Account, message: NotifyMessage) async throws {
        let url = URL(string: "https://\(InputConfig.notifyHost)/\(InputConfig.gmDappProjectId)/notify")!
        var request = URLRequest(url: url)
        let notifyRequestPayload = NotifyRequest(notification: message, accounts: [account])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let payload = try encoder.encode(notifyRequestPayload)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(InputConfig.gmDappProjectSecret)", forHTTPHeaderField: "Authorization")
        request.httpBody = payload
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Notify error") }
    }
}

struct NotifyRequest: Codable {
    let notification: NotifyMessage
    let accounts: [Account]
}
