import Foundation

public struct RecapData: Codable {
    var att: [String: [String: [AnyCodable]]]?
    var prf: [String]?
}

public struct RecapUrn {
    enum Errors: Error {
        case invalidUrn
        case invalidPayload
        case invalidJsonStructure
    }

    public let urn: String
    public let recapData: RecapData

    public init(urn: String) throws {
        guard urn.hasPrefix("urn:recap") else { throw Errors.invalidUrn }

        let components = urn.components(separatedBy: ":")
        guard components.count > 2 else {
            throw Errors.invalidPayload
        }

        let base64urlEncodedPayload = components.dropFirst(2).joined(separator: ":")
        guard let jsonData = Data(base64urlEncoded: base64urlEncodedPayload) else {
            throw Errors.invalidPayload
        }

        do {
            self.recapData = try JSONDecoder().decode(RecapData.self, from: jsonData)
        } catch {
            throw Errors.invalidJsonStructure
        }

        self.urn = urn
    }
}

public extension Data {
    /// Initializes a Data object with a base64url encoded String.
    init?(base64urlEncoded: String) {
        var base64 = base64urlEncoded
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if necessary
        while base64.count % 4 != 0 {
            base64 += "="
        }

        self.init(base64Encoded: base64)
    }

    /// Returns a base64url encoded String.
    func base64urlEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: ["="]) // Remove any padding
    }
}
