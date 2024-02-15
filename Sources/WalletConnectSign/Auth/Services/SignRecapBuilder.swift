
import Foundation

import Foundation

import Foundation

struct SignRecapBuilder {
    enum BuilderError: Error {
        case nonEVMChainNamespace
        case emptySupportedChainsOrMethods
    }

    static func build(requestedSessionRecap urn: String, requestedChains: [String], supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> SignRecap {
        // Validate non-empty supported chains and methods
        guard !supportedEVMChains.isEmpty, !supportedMethods.isEmpty else {
            throw BuilderError.emptySupportedChainsOrMethods
        }

        // Ensure all supported chains are EVM chains
        guard supportedEVMChains.allSatisfy({ $0.namespace == "eip155" }) else {
            throw BuilderError.nonEVMChainNamespace
        }

        // Convert supportedEVMChains to string array for intersection
        let supportedChainStrings = supportedEVMChains.map { $0.absoluteString }

        // Find intersection of requestedChains and supportedEVMChains strings
        let commonChains = requestedChains.filter(supportedChainStrings.contains)

        let requestedRecap = try SignRecap(urn: urn)

        // Initialize eip155 actions to an empty dictionary to ensure eip155 entry is always present
        var filteredActions: [String: [String: [AnyCodable]]] = ["eip155": [:]]

        // Populate filteredActions with methods and intersected chains if there are common chains
        if !commonChains.isEmpty {
            for method in supportedMethods {
                let actionKey = "request/\(method)"
                if requestedRecap.recapData.att?["eip155"]?.keys.contains(actionKey) ?? false {
                    // Use only common chains for each supported method
                    filteredActions["eip155"]![actionKey] = [AnyCodable(["chains": commonChains])]
                }
            }
        }

        // Regardless of whether there are common chains or supported methods, "eip155" is always present, potentially empty

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
