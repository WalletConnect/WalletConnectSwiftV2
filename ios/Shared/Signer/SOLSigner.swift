import Foundation
import Commons
import SolanaSwift
import TweetNacl

struct SOLSigner {

    static var address: String {
        return account.publicKey.base58EncodedString
    }

    private static let account: Account = {
        let key = "4eN1YZm598FtdigriE5int7Gf5dxs58rzVh3ftRwxjkYXxkiDiweuvkop2Kr5Td174DcbVdDxzjWqQ96uir3NYka"
        return try! Account(secretKey: Data(Base58.decode(key)))
    }()

    private init() {}

    static func signTransaction(_ params: AnyCodable) -> AnyCodable {
        let transaction = try! params.get(SolSignTransaction.self)
        let message = try! transaction.transaction.compileMessage()
        let serializedMessage = try! message.serialize()
        let signature = try! NaclSign.signDetached(
            message: serializedMessage,
            secretKey: account.secretKey
        )
        return AnyCodable(["signature": Base58.encode(signature)])
    }
}

private struct SolSignTransaction: Codable {
    let instructions: [TransactionInstruction]
    let recentBlockhash: String
    let feePayer: PublicKey

    var transaction: Transaction {
        return Transaction(
            instructions: instructions,
            recentBlockhash: recentBlockhash,
            feePayer: feePayer
        )
    }
}
