import Foundation

struct WalletConnectRPCID: IdentifierGenerator {

    func next() -> RPCID {
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000 * pow(10, 6))
        let random = Int64.random(in: 0..<1000000)
        return .right(Int64(timestamp + random))
    }
}
