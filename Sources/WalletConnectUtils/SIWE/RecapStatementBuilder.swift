
import Foundation

struct RecapUrn {
    enum Errors: Error {
        case invalidUrn
    }
    init(urn: String) throws {
        guard urn.hasPrefix("urn:recap") else { throw Errors.invalidUrn }
        self.urn = urn
    }
    let urn: String
}

struct RecapStatementBuilder {
    static func buildRecapStatement(recapUrns: [RecapUrn]) -> String {
        var statementParts: [String] = []

        recapUrns.forEach { urn in
            let decodedRecap = decodeUrnToJson(urn: urn)
            guard let attValue = decodedRecap["att"] else { return }


            // sort resources keys for consistancy in the statement
            let sortedResourceKeys = attValue.keys.sorted()

            for resourceKey in sortedResourceKeys {
                guard let actions = attValue[resourceKey] else { continue }
                var requestActions: [String] = []

                for (actionType, _) in actions where actionType.starts(with: "request/") {
                    let action = actionType.replacingOccurrences(of: "request/", with: "")
                    requestActions.append("'\(action)'")
                }

                // sorting is required as dictionary doesn't guarantee the order of elements
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


    private static func decodeUrnToJson(urn: RecapUrn) -> [String: [String: [String: [String]]]] {
        // Decode the Base64 encoded JSON
        guard let jsonData = Data(base64Encoded: urn.urn) else { return nil }

        // Deserialize the JSON data into the desired dictionary
        do {
            let decodedDictionary = try JSONDecoder().decode([String: [String: [String: [String]]]].self, from: jsonData)
            return decodedDictionary
        } catch {
            return nil
        }
    }
}
