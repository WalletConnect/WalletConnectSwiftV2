import Foundation

public protocol JWTEncodable: Codable, Equatable {
    func encode() throws -> String

    static func decode(from string: String) throws -> Self
}

extension JWTEncodable {

    public func encode() throws -> String {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        let data = try jsonEncoder.encode(self)
        return JWTEncoder.base64urlEncodedString(data: data)
    }

    public static func decode(from string: String) throws -> Self {
        let data = try JWTEncoder.base64urlDecodedData(string: string)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
