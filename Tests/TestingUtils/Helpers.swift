import Foundation
import WalletConnectUtils
import Commons

public let defaultTimeout: TimeInterval = 5.0

public extension String {
    static func randomTopic() -> String {
        "\(UUID().uuidString)\(UUID().uuidString)".replacingOccurrences(of: "-", with: "").lowercased()
    }
}

extension AnyCodable {
    static func decoded<C>(_ codable: C) -> AnyCodable where C: Codable {
        let encoded = try! JSONEncoder().encode(codable)
        return try! JSONDecoder().decode(AnyCodable.self, from: encoded)
    }
}
