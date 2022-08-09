import Foundation
import WalletConnectUtils

public let defaultTimeout: TimeInterval = 5.0

public extension Int {
    static func random() -> Int {
        random(in: Int.min...Int.max)
    }
}

public extension Int64 {
    static func random() -> Int64 {
        random(in: Int64.min...Int64.max)
    }
}

public extension Double {

    // Do not use this function when testing Codables: https://bugs.swift.org/browse/SR-7054
    static func random() -> Double {
        random(in: 0...1)
    }
}

public extension String {

    static func random() -> String {
        randomTopic()
    }

    static func randomTopic() -> String {
        "\(UUID().uuidString)\(UUID().uuidString)".replacingOccurrences(of: "-", with: "").lowercased()
    }
}

public extension Result {

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

extension AnyCodable {
    static func decoded<C>(_ codable: C) -> AnyCodable where C: Codable {
        let encoded = try! JSONEncoder().encode(codable)
        return try! JSONDecoder().decode(AnyCodable.self, from: encoded)
    }
}
