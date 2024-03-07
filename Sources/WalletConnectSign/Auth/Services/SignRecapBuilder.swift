import Foundation


struct SignRecapBuilder {

    enum BuilderError: Error {
        case nonEVMChainNamespace
        case emptySupportedChainsOrMethods
        case noCommonChains
    }

    static func build(requestedSessionRecap urn: String, requestedChains: [String], supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> SignRecap {
        guard !supportedEVMChains.isEmpty, !supportedMethods.isEmpty else {
            throw BuilderError.emptySupportedChainsOrMethods
        }

        guard supportedEVMChains.allSatisfy({ $0.namespace == "eip155" }) else {
            throw BuilderError.nonEVMChainNamespace
        }

        // Convert supportedEVMChains to string array for intersection
        let supportedChainStrings = supportedEVMChains.map { $0.absoluteString }

        // Find intersection of requestedChains and supportedEVMChains strings
        let commonChains = requestedChains.filter(supportedChainStrings.contains)
        guard !commonChains.isEmpty else {
            throw BuilderError.noCommonChains
        }

        let requestedRecap = try SignRecap(urn: urn)

        var filteredActions: [String: [String: [AnyCodable]]] = [:]

        if let eip155Actions = requestedRecap.recapData.att?["eip155"] {
            for method in supportedMethods {
                let actionKey = "request/\(method)"
                if eip155Actions.keys.contains(actionKey) {
                    // Use only common chains for each supported method
                    filteredActions["eip155", default: [:]][actionKey] = [AnyCodable(["chains": commonChains])]
                }
            }
        }

        let modifiedRecapData = SignRecap.RecapData(att: filteredActions, prf: requestedRecap.recapData.prf)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(modifiedRecapData) else {
            throw SignRecap.Errors.invalidRecapStructure
        }
        let jsonBase64String = jsonData.base64EncodedString()

        let modifiedUrn = "urn:recap:\(jsonBase64String)"
        return try SignRecap(urn: modifiedUrn)
    }
}
