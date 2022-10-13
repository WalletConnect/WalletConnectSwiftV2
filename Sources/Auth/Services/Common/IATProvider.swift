import Foundation

protocol IATProvider {
    var iat: String { get }
}

struct DefaultIATProvider: IATProvider {
    var iat: String {
        return ISO8601DateFormatter().string(from: Date())
    }
}
