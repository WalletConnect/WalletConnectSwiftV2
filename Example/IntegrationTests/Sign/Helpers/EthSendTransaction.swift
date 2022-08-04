import Foundation

struct EthSendTransaction: Codable, Equatable {
    let from: String
    let data: String
    let value: String
    let to: String
    let gasPrice: String
    let nonce: String

    static func stub() -> EthSendTransaction {
        try! JSONDecoder().decode(EthSendTransaction.self, from: ethSendTransactionJSON.data(using: .utf8)!)
    }

    private static let ethSendTransactionJSON = """
{
    "from":"0xb60e8dd61c5d32be8058bb8eb970870f07233155",
    "to":"0xd46e8dd67c5d32be8058bb8eb970870f07244567",
    "data":"0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675",
    "gas":"0x76c0",
    "gasPrice":"0x9184e72a000",
    "value":"0x9184e72a",
    "nonce":"0x117"
}
"""
}
