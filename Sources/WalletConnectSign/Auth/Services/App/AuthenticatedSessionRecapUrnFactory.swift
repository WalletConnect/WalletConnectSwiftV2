import Foundation

class AuthenticatedSessionRecapUrnFactory {
    static func createNamespaceRecap(methods: [String]) throws -> String {
        let actions = methods.map{"request/\($0)"}
        let recap = RecapFactory.createRecap(resource: "eip155", actions: actions)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        let jsonData = try jsonEncoder.encode(recap)
        let base64urlEncoded = jsonData.base64urlEncodedString()
        let urn = "urn:recap:\(base64urlEncoded)"
        return urn
    }
}
