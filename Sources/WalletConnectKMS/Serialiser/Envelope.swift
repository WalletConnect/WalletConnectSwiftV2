import Foundation
import WalletConnectUtils

/// A type representing envelope with it's serialization policy
public struct Envelope: Equatable {
    enum Errors: String, Error {
        case malformedEnvelope
        case unsupportedEnvelopeType
    }

    let type: EnvelopeType
    let sealbox: Data

    /// - Parameter base64encoded: base64encoded envelope
    /// tp = type byte (1 byte)
    /// pk = public key (32 bytes)
    /// iv = initialization vector (12 bytes)
    /// ct = ciphertext (N bytes)
    /// sealbox = iv + ct + tag
    /// type0: tp + sealbox
    /// type1: tp + pk + sealbox
    init(_ base64encoded: String) throws {
        guard let envelopeData = Data(base64Encoded: base64encoded) else {
            throw Errors.malformedEnvelope
        }
        let envelopeTypeByte = envelopeData.subdata(in: 0..<1).first
        if envelopeTypeByte == 0 {
            self.type = .type0
            self.sealbox = envelopeData.subdata(in: 1..<envelopeData.count)
        } else if envelopeTypeByte == 1 {
            guard envelopeData.count > 33 else {throw Errors.malformedEnvelope}
            let pubKey = envelopeData.subdata(in: 1..<33)
            self.type = .type1(pubKey: pubKey)
            self.sealbox = envelopeData.subdata(in: 33..<envelopeData.count)
        } else {
            throw Errors.unsupportedEnvelopeType
        }
    }

    init(type: EnvelopeType, sealbox: Data) {
        self.type = type
        self.sealbox = sealbox
    }

    func serialised() -> String {
        switch type {
        case .type0:
            return (type.representingByte.data + sealbox).base64EncodedString()
        case .type1(let pubKey):
            return (type.representingByte.data + pubKey + sealbox).base64EncodedString()
        }
    }

}

public extension Envelope {
    enum EnvelopeType: Equatable {
        /// type 0 = tp + iv + ct + tag
        case type0
        /// type 1 = tp + pk + iv + ct + tag
        case type1(pubKey: Data)

        var representingByte: UInt8 {
            switch self {
            case .type0:
                return 0
            case .type1:
                return 1
            }
        }
    }
}
