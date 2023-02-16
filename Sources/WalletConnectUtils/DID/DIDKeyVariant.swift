import Foundation

public enum DIDKeyVariant {
    case ED25519
    case X25519

    var header: [UInt8] {
        switch self {
        case .ED25519:
            return [0xed, 0x01]
        case .X25519:
            return [0xec, 0x01]
        }
    }
}
