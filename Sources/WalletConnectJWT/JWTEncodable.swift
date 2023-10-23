import Foundation

public protocol JWTEncodable: Codable, Equatable {
    func encode(jsonEncoder: JSONEncoder) throws -> String

    static func decode(from string: String) throws -> Self
}

extension JWTEncodable {

    public func encode(jsonEncoder: JSONEncoder) throws -> String {
        let data = try jsonEncoder.encode(self)
        return JWTEncoder.base64urlEncodedString(data: data)
    }

    public static func decode(from string: String) throws -> Self {
        let data = try JWTEncoder.base64urlDecodedData(string: string)
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
