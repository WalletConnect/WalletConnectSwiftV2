import Foundation

class AuthenticatedSessionRecapUrnFactory {
    static func createNamespaceRecap(methods: [String]) throws -> String {
        let actions = methods.map{"request/\($0)"}
        let recap = RecapFactory.createRecap(resource: "eip155", actions: actions)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        let jsonData = try jsonEncoder.encode(recap)
        let base64Encoded = jsonData.base64EncodedString()
        let urn = "urn:recap:\(base64Encoded)"
        return urn
    }
}
