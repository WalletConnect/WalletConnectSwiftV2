import Foundation
import CryptoSwift

extension Data {

    var keccak256: Data {
        return sha3(.keccak256)
    }
}
