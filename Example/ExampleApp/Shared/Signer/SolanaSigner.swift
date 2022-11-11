import Foundation
import Commons
import SolanaSwift
import TweetNacl

struct SolanaSigner {

    static var address: String {
        return account.publicKey.base58EncodedString
    }

    private static let account: Account = {
//        let phrase = "cargo morning orient cannon ship code journey walnut cycle cupboard width high"
        let key = "4eN1YZm598FtdigriE5int7Gf5dxs58rzVh3ftRwxjkYXxkiDiweuvkop2Kr5Td174DcbVdDxzjWqQ96uir3NYka"
        return try! Account(secretKey: Data(Base58.decode(key)))
    }()

    private init() {}

    static func signTransaction(_ params: AnyCodable) -> AnyCodable {
        let transaction = try! params.get(SolSignTransaction.self)
        print("Transaction:::\n\(String(describing: params.value))")

        let message = try! transaction.transaction.compileMessage()
        let serializedMessage = try! message.serialize()

        let signature = try! NaclSign.signDetached(
            message: serializedMessage,
            secretKey: account.secretKey
        )
        return AnyCodable(["signature": Base58.encode(signature)])
    }
}

fileprivate struct SolSignTransaction: Codable {
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

fileprivate struct Signature: Codable {
    struct Sig: Codable {
        let data: [UInt8]
    }
    let signature: Sig?
    let publicKey: PublicKey
}
