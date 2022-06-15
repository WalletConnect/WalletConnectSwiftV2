import Foundation

public struct AgreementKeys: Equatable {

    public let sharedKey: SymmetricKey
    public let publicKey: AgreementPublicKey

    public func derivedTopic() -> String {
        sharedKey.rawRepresentation.sha256().toHexString()
    }
}

extension AgreementKeys: GenericPasswordConvertible {
    enum Error: Swift.Error {
        case invalidBufferLenght
    }
    public init<D>(rawRepresentation data: D) throws where D: ContiguousBytes {
        let buffer = data.withUnsafeBytes { Data($0) }
        guard buffer.count == 64 else {
            throw Error.invalidBufferLenght
        }
        let symKeyRaw = buffer.subdata(in: 0..<32)
        self.sharedKey = try SymmetricKey(rawRepresentation: symKeyRaw)
        self.publicKey = try AgreementPublicKey(rawRepresentation: buffer.subdata(in: 32..<64))
    }

    public var rawRepresentation: Data {
        sharedKey.rawRepresentation + publicKey.rawRepresentation
    }
}
