
import Foundation

class SessionNamespaceBuilder {
    enum Errors: Error {
        case emptyCacaosArrayForbidden
        case cannotCreateSessionNamespaceFromTheRecap
        case malformedRecap
    }
    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) {
        self.logger = logger
    }

    func buildSessionNamespaces(cacaos: [Cacao]) throws -> [String: SessionNamespace] {
        guard !cacaos.isEmpty else {
            throw Errors.emptyCacaosArrayForbidden
        }

        // Get the first "urn:recap" resource from the first cacao
        guard let recapUrn = cacaos.first?.p.resources?.first(where: { $0.hasPrefix("urn:recap") }) else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        // Check if all cacaos have exactly the same first "urn:recap" resource
        for cacao in cacaos {
            guard let resources = cacao.p.resources,
                  resources.contains(recapUrn) else {
                throw Errors.malformedRecap
            }
        }

        guard let decodedRecap = decodeUrnToJson(urn: recapUrn),
              let chainsNamespace = try? DIDPKH(did: cacaos.first!.p.iss).account.blockchain.namespace else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let accounts = cacaos.compactMap { try? DIDPKH(did: $0.p.iss).account }

        let accountsSet = Set(accounts)
        let methods = getMethods(from: decodedRecap)

        let sessionNamespace = SessionNamespace(accounts: accountsSet, methods: methods, events: [])
        return [chainsNamespace: sessionNamespace]
    }


    private func decodeUrnToJson(urn: String) -> [String: [String: [String: [String]]]]? {
        // Extract the Base64 encoded JSON part from the URN
        let components = urn.components(separatedBy: ":")
        guard components.count >= 3, let base64EncodedJson = components.last else {
            logger.debug("Invalid URN format")
            return nil
        }

        // Decode the Base64 encoded JSON
        guard let jsonData = Data(base64Encoded: base64EncodedJson) else {
            logger.debug("Failed to decode Base64 string")
            return nil
        }

        // Deserialize the JSON data into the desired dictionary
        do {
            let decodedDictionary = try JSONDecoder().decode([String: [String: [String: [String]]]].self, from: jsonData)
            return decodedDictionary
        } catch {
            logger.debug("Error during JSON decoding: \(error.localizedDescription)")
            return nil
        }
    }

    func getMethods(from recap: [String: [String: [String: [String]]]]) -> Set<String> {
        var requestMethods: [String] = []

        // Iterate through the recap dictionary
        for (_, resources) in recap {
            for (_, requests) in resources {
                for (key, _) in requests {

                // Check if the key starts with "request/"
                    if key.hasPrefix("request/") {
                        // Extract the method name and add it to the array
                        let methodName = String(key.dropFirst("request/".count))
                        requestMethods.append(methodName)
                    }
                }
            }
        }

        return Set(requestMethods)
    }

}
