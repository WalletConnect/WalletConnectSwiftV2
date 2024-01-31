import Foundation

struct RecapUrn {
    enum Errors: Error {
        case invalidUrn
    }
    let urn: String

    init(urn: String) throws {
        guard urn.hasPrefix("urn:recap") else { throw Errors.invalidUrn }
        self.urn = urn
    }

    // Extracts the Base64-encoded JSON portion of the URN
    func decodedPayload() -> Data? {
        let components = urn.components(separatedBy: ":")
        guard components.count > 2 else { return nil }
        let base64Part = components.dropFirst(2).joined(separator: ":")
        return Data(base64Encoded: base64Part)
    }
}

struct RecapStatementBuilder {
    static func buildRecapStatement(recapUrns: [RecapUrn]) -> String {
        var statementParts: [String] = []

        recapUrns.forEach { urn in
            guard let jsonData = urn.decodedPayload() else { return }
            guard let decodedRecap: [String: [String: [String: [String]]]] = decodeUrnToJson(jsonData: jsonData) else { return }

            guard let attValue = decodedRecap["att"] else { return }
            let sortedResourceKeys = attValue.keys.sorted()

            for resourceKey in sortedResourceKeys {
                guard let actions = attValue[resourceKey] else { continue }
                var requestActions: [String] = []

                for (actionType, _) in actions where actionType.starts(with: "request/") {
                    let action = actionType.replacingOccurrences(of: "request/", with: "")
                    requestActions.append("'\(action)'")
                }

                requestActions.sort()

                if !requestActions.isEmpty {
                    let actionsString = requestActions.joined(separator: ", ")
                    statementParts.append("'request': \(actionsString) for '\(resourceKey)'")
                }
            }
        }

        if !statementParts.isEmpty {
            let formattedStatement = statementParts.joined(separator: "; ")
            return "I further authorize the stated URI to perform the following actions: (1) \(formattedStatement)."
        } else {
            return ""
        }
    }

    private static func decodeUrnToJson<T: Decodable>(jsonData: Data) -> T? {
        do {
            let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
            return decodedObject
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}
