import Foundation

struct JWTEncoder {
    /// Returns a `String` representation of this data, encoded in base64url format
    /// as defined in RFC4648 (https://tools.ietf.org/html/rfc4648).
    ///
    /// This is the appropriate format for encoding the header and claims of a JWT.
    public static func base64urlEncodedString(data: Data) -> String {
        let result = data.base64EncodedString()
        return result.replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    public static func base64urlDecodedData(string: String) throws -> Data {
        guard let result = Data(base64url: string)
        else { throw JWTError.notBase64String }
        return result
    }
}
