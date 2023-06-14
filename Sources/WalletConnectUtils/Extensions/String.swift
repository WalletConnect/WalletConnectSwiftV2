import Foundation

public extension String {

    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }

    static func generateTopic() -> String {
        let keyData = Data.randomBytes(count: 32)
        return keyData.toHexString()
    }

    func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw Errors.notAnURL }
        return url
    }
}

fileprivate enum Errors: Error {
    case notAnURL
}
