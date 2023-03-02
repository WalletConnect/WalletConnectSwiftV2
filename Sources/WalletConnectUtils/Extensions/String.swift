import Foundation

public extension String {

    enum Errors: Error {
        case notAnURL
    }

    func toHexEncodedString(uppercase: Bool = true, prefix: String = "", separator: String = "") -> String {
        return unicodeScalars.map { prefix + .init($0.value, radix: 16, uppercase: uppercase) } .joined(separator: separator)
    }

    static func generateTopic() -> String {
        let keyData = Data.randomBytes(count: 32)
        return keyData.toHexString()
    }

    init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        let bytes = data.withUnsafeBytes { Data(Array($0)) }
        guard let string = String(data: bytes, encoding: .utf8) else {
            fatalError() // FIXME: Throw error
        }
        self = string
    }

    var rawRepresentation: Data {
        self.data(using: .utf8) ?? Data()
    }

    func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw Errors.notAnURL }
        return url
    }
}
