import Foundation

extension JSONEncoder {

    public static var jwt: JSONEncoder {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        jsonEncoder.dateEncodingStrategy = .secondsSince1970
        return jsonEncoder
    }
}
