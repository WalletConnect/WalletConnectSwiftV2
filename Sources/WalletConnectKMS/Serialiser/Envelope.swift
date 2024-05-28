import Foundation

/// A type representing envelope with it's serialization policy
public struct Envelope: Equatable {
    public enum CodingType: Equatable, Codable {
        case base64Encoded
        case base64UrlEncoded
    }
    public enum Errors: String, Error {
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
    /// sealbox: in case of envelope type 0, 1: = iv + ct + tag, in case of type 2 - raw data representation of a json object
    /// type0: tp + sealbox
    /// type1: tp + pk + sealbox
    init(_ codingType: CodingType, envelopeString: String) throws {
        var envelopeData: Data!
        switch codingType {
        case .base64Encoded:
            envelopeData = Data(base64Encoded: envelopeString)
        case .base64UrlEncoded:
            envelopeData = Data(base64url: envelopeString)
        }
        guard let envelopeData = envelopeData else { throw Errors.malformedEnvelope }

        guard let envelopeTypeByte = envelopeData.subdata(in: 0..<1).first else { throw Errors.malformedEnvelope }

        let pubKey: Data? = (envelopeTypeByte == 1) && envelopeData.count >= 33 ? envelopeData.subdata(in: 1..<33) : nil
        self.type = try EnvelopeType(representingByte: envelopeTypeByte, pubKey: pubKey)

        let startIndex = (envelopeTypeByte == 1) ? 33 : 1
        self.sealbox = envelopeData.subdata(in: startIndex..<envelopeData.count)
    }


    init(type: EnvelopeType, sealbox: Data, codingType: CodingType) {
        self.type = type
        self.sealbox = sealbox
    }

    func serialised(codingType: CodingType) -> String {
        let dataToEncode: Data
        switch type {
        case .type0:
            dataToEncode = type.representingByte.data + sealbox
        case .type1(let pubKey):
            dataToEncode = type.representingByte.data + pubKey + sealbox
        case .type2:
            dataToEncode = type.representingByte.data + sealbox
        }

        switch codingType {
        case .base64Encoded:
            return dataToEncode.base64EncodedString()
        case .base64UrlEncoded:
            return dataToEncode.base64urlEncodedString()
        }
    }

}

public extension Envelope {
    enum EnvelopeType: Equatable {
        /// type 0 = tp + iv + ct + tag
        case type0
        /// type 1 = tp + pk + iv + ct + tag - base64encoded
        case type1(pubKey: Data)
        /// type 2 = tp + base64urlEncoded unencrypted string
        case type2

        var representingByte: UInt8 {
            switch self {
            case .type0:
                return 0
            case .type1:
                return 1
            case .type2:
                return 2
            }
        }

        init(representingByte: UInt8, pubKey: Data?) throws {
            switch representingByte {
            case 0:
                self = .type0
            case 1:
                guard let key = pubKey, key.count == 32 else {
                    throw Envelope.Errors.malformedEnvelope
                }
                self = .type1(pubKey: key)
            case 2:
                self = .type2
            default:
                throw Envelope.Errors.unsupportedEnvelopeType
            }
        }
    }
}
