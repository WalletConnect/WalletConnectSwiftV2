
import Foundation

class SessionNamespaceBuilder {
    enum Errors: Error {
        case recordForIdNotFound
        case malformedAuthRequestParams
        case cannotCreateSessionNamespaceFromTheRecap
    }
    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) {
        self.logger = logger
    }

    func buildSessionNamespaces(cacaos: [Cacao]) throws -> [String: SessionNamespace] {

        guard let cacao = cacaos.first,
              let resources = cacao.p.resources,
              let namespacesUrn = resources.last,
              let decodedRecap = decodeUrnToJson(urn: namespacesUrn),
              let chainsNamespace = try? DIDPKH(did: cacao.p.iss).account.blockchain.namespace else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let accounts = cacaos.compactMap{ try? DIDPKH(did: $0.p.iss).account }

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

