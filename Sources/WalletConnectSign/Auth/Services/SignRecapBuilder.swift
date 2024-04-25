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

        let supportedChainStrings = supportedEVMChains.map { $0.absoluteString }
        let commonChains = requestedChains.filter(supportedChainStrings.contains)
        guard !commonChains.isEmpty else {
            throw BuilderError.noCommonChains
        }

        let requestedRecap = try SignRecap(urn: urn)
        var filteredActions = requestedRecap.recapData.att ?? [:]

        if let eip155Actions = filteredActions["eip155"] {
            var newEip155Actions: [String: [AnyCodable]] = [:]
            for method in supportedMethods {
                let actionKey = "request/\(method)"
                if let actions = eip155Actions[actionKey] {
                    newEip155Actions[actionKey] = [AnyCodable(["chains": commonChains])]
                }
            }
            filteredActions["eip155"] = newEip155Actions
        }

        let modifiedRecapData = SignRecap.RecapData(att: filteredActions, prf: requestedRecap.recapData.prf)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(modifiedRecapData) else {
            throw SignRecap.Errors.invalidRecapStructure
        }
        let jsonBase64urlString = jsonData.base64urlEncodedString()

        let modifiedUrn = "urn:recap:\(jsonBase64urlString)"
        return try SignRecap(urn: modifiedUrn)
    }

}
