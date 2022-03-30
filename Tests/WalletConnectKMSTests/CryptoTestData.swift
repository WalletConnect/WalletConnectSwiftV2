// 

import Foundation

enum CryptoTestData {
    static let privateKeyA = Data(hex: "1fb63fca5c6ac731246f2f069d3bc2454345d5208254aa8ea7bffc6d110c8862")
    static let publicKeyA = Data(hex: "ff7a7d5767c362b0a17ad92299ebdb7831dcbd9a56959c01368c7404543b3342")
    static let privateKeyB = Data(hex: "36bf507903537de91f5e573666eaa69b1fa313974f23b2b59645f20fea505854")
    static let publicKeyB = Data(hex: "590c2c627be7af08597091ff80dd41f7fa28acd10ef7191d7e830e116d3a186a")
    static let expectedSharedKey = Data(hex: "0653ca620c7b4990392e1c53c4a51c14a2840cd20f0f1524cf435b17b6fe988c")
}
