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
        var actionCounter: Int = 1

        recapUrns.forEach { urn in
            guard let jsonData = urn.decodedPayload() else { return }
            guard let decodedRecap: [String: [String: [String: [String]]]] = decodeUrnToJson(jsonData: jsonData) else { return }

            guard let attValue = decodedRecap["att"] else { return }
            let sortedResourceKeys = attValue.keys.sorted()

            for resourceKey in sortedResourceKeys {
                guard let actions = attValue[resourceKey] else { continue }
                var actionsByType: [String: [String]] = [:]

                // Grouping actions by their prefix
                for (actionType, _) in actions {
                    let components = actionType.split(separator: "/").map(String.init)
                    guard components.count > 1 else { continue }
                    let prefix = components[0]
                    let action = components.dropFirst().joined(separator: "/")

                    actionsByType[prefix, default: []].append(action)
                }

                // Sorting the action types (prefixes) alphabetically
                let sortedActionTypes = actionsByType.keys.sorted()

                // Constructing statement parts from sorted actions
                for prefix in sortedActionTypes {
                    guard let actionList = actionsByType[prefix] else { continue }
                    let sortedActionList = actionList.sorted().map { "'\($0)'" }.joined(separator: ", ")
                    statementParts.append("(\(actionCounter)) '\(prefix)': \(sortedActionList) for '\(resourceKey)'")
                    actionCounter += 1
                }
            }
        }

        if !statementParts.isEmpty {
            let formattedStatement = statementParts.joined(separator: ". ")
            return "I further authorize the stated URI to perform the following actions on my behalf: \(formattedStatement)."
        } else {
            return "No actions authorized."
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
