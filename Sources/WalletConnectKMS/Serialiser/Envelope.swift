import Foundation
import WalletConnectUtils

/// A type representing envelope with it's serialization policy
public struct Envelope {
    enum Errors: String, Error {
        case malformedEnvelope
        case unsupportedEnvelopeType
    }

    public let type: EnvelopeType
    public let sealbox: Data

    /// - Parameter base64encoded: base64encoded envelope
    /// tp = type byte (1 byte)
    /// pk = public key (32 bytes)
    /// iv = initialization vector (12 bytes)
    /// ct = ciphertext (N bytes)
    /// sealbox = iv + ct + tag
    /// type0: tp + sealbox
    /// type1: tp + pk + sealbox
    public init(_ base64encoded: String) throws {
        guard let envelopeData = Data(base64Encoded: base64encoded) else {
            throw Errors.malformedEnvelope
        }
        let envelopeTypeByte = envelopeData.subdata(in: 0..<1).uint8
        if envelopeTypeByte == 0 {
            self.type = .type0
            self.sealbox = envelopeData.subdata(in: 1..<envelopeData.count)
        } else if envelopeTypeByte == 1 {
            let pubKey = try AgreementPublicKey(hex: envelopeData.subdata(in: 0..<33).toHexString())
            self.type = .type1(pubKey: pubKey)
            self.sealbox = envelopeData.subdata(in: 33..<envelopeData.count)
        } else {
            throw Errors.unsupportedEnvelopeType
        }
    }

}

public extension Envelope {
    enum EnvelopeType {
        enum Errors: Error {
            case unsupportedPolicyType
        }
        /// type 0 = tp + iv + ct + tag
        case type0
        /// type 1 = tp + pk + iv + ct + tag
        case type1(pubKey: AgreementPublicKey)

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
