import Foundation

struct JWTHeader: JWTEncodable {
    var alg: String!
    let typ: String

    init(alg: String? = nil) {
        self.alg = alg
        typ  = "JWT"
    }
}
