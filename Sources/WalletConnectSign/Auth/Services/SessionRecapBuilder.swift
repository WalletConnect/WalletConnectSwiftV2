
import Foundation

struct SessionRecapBuilder {

    enum BuilderError: Error {
        case nonEVMChainNamespace
        case emptySupportedChainsOrMethods
    }

    static func build(requestedSessionRecap urn: String, supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> SessionRecap {
        // Ensure supported chains are EVM chains and methods are not empty
        guard !supportedEVMChains.isEmpty, !supportedMethods.isEmpty else {
            throw BuilderError.emptySupportedChainsOrMethods
        }

        guard supportedEVMChains.allSatisfy({ $0.namespace == "eip155" }) else {
            throw BuilderError.nonEVMChainNamespace
        }
        // Decode the requestedSessionRecap into a SessionRecap object
        let requestedRecap = try SessionRecap(urn: urn)

        // Initialize filteredActions to potentially include all supported methods
        var filteredActions: [String: [String: [AnyCodable]]] = [:]

        // Check if `eip155` actions exist in the requested recap
        if let eip155Actions = requestedRecap.recapData.att?["eip155"] {
            for method in supportedMethods {
                let actionKey = "request/\(method)"
                if eip155Actions.keys.contains(actionKey) {
                    let supportedChainsCodable = supportedEVMChains.map { $0.absoluteString }
                    filteredActions["eip155", default: [:]][actionKey] = [AnyCodable(["chains": supportedChainsCodable])]
                }
            }
        }

        // Encode the filtered RecapData back into a base64 string
        let modifiedRecapData = SessionRecap.RecapData(att: filteredActions, prf: requestedRecap.recapData.prf)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(modifiedRecapData) else {
            throw SessionRecap.Errors.invalidRecapStructure
        }
        let jsonBase64String = jsonData.base64EncodedString()

        // Create a new SessionRecap object with the modified data
        let modifiedUrn = "urn:recap:\(jsonBase64String)"
        return try SessionRecap(urn: modifiedUrn)
    }

}
