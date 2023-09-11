import Foundation

public struct DIDWeb {

    public let host: String

    public init(url: URL) throws {
        guard let host = url.host else { throw Errors.invalidUrl }
        self.host = host
    }

    public init(did: String) throws {
        guard let host = did.components(separatedBy: ":").last else { throw Errors.invalidDid }
        self.host = host
    }

    public init(host: String) {
        self.host = host
    }

    public var did: String {
        return "did:web:\(host)"
    }
}

extension DIDWeb {

    enum Errors: Error {
        case invalidUrl
        case invalidDid
    }
}
