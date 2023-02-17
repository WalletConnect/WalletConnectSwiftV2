import Foundation

extension JWT {
    struct Header: Codable, Equatable {
        var alg: String!
        let typ: String

        init(alg: String? = nil) {
            self.alg = alg
            typ  = "JWT"
        }

        func encode() throws -> String {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .secondsSince1970
            jsonEncoder.outputFormatting = .withoutEscapingSlashes
            let data = try jsonEncoder.encode(self)
            return JWTEncoder.base64urlEncodedString(data: data)
        }
    }
}
