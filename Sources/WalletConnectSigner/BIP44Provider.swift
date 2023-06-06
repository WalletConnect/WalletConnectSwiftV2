import Foundation

public enum DerivationPath {
    case hardened(UInt32)
    case notHardened(UInt32)
}

public protocol BIP44Provider {
    func derive(entropy: Data, path: [DerivationPath]) -> Data
}
