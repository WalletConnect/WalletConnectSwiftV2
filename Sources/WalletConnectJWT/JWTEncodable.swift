import Foundation

protocol JWTEncodable: Codable, Equatable {
    func encode() throws -> String
}

extension JWTEncodable {

    func encode() throws -> String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        let data = try jsonEncoder.encode(self)
        return JWTEncoder.base64urlEncodedString(data: data)
    }
}
