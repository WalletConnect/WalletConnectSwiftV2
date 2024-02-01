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

struct RecapData: Decodable {
    var att: [String: [String: [AnyCodable]]]?
    var prf: [String]?
}

struct RecapStatementBuilder {
    static func buildRecapStatement(recapUrns: [RecapUrn]) -> String {
        var statementParts: [String] = []
        var actionCounter: Int = 1

        recapUrns.forEach { urn in
            guard let jsonData = urn.decodedPayload() else { return }
            guard let decodedRecap = try? JSONDecoder().decode(RecapData.self, from: jsonData) else {
                print("Error decoding JSON")
                return
            }

            guard let attValue = decodedRecap.att else { return }
            let sortedResourceKeys = attValue.keys.sorted()

            for resourceKey in sortedResourceKeys {
                guard let actions = attValue[resourceKey] else { continue }
                var actionsByType: [String: [String]] = [:]

                for actionType in actions.keys {
                    let action = actionType.split(separator: "/").dropFirst().joined(separator: "/")
                    actionsByType[String(actionType.split(separator: "/").first!), default: []].append(action)
                }

                actionsByType.sorted(by: { $0.key < $1.key }).forEach { prefix, actions in
                    let formattedActions = actions.sorted().map { "'\($0)'" }.joined(separator: ", ")
                    statementParts.append("(\(actionCounter)) '\(prefix)': \(formattedActions) for '\(resourceKey)'")
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
}
