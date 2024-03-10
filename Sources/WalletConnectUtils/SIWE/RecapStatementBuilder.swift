import Foundation

public struct RecapUrn {
    enum Errors: Error {
        case invalidUrn
        case invalidPayload
        case invalidJsonStructure
    }

    public let urn: String
    public let recapData: RecapData

    public init(urn: String) throws {
        guard urn.hasPrefix("urn:recap") else { throw Errors.invalidUrn }

        let components = urn.components(separatedBy: ":")
        guard components.count > 2, let jsonData = Data(base64Encoded: components.dropFirst(2).joined(separator: ":")) else {
            throw Errors.invalidPayload
        }

        do {
            self.recapData = try JSONDecoder().decode(RecapData.self, from: jsonData)
        } catch {
            throw Errors.invalidJsonStructure
        }

        self.urn = urn
    }
}

public struct RecapData: Codable {
    var att: [String: [String: [AnyCodable]]]?
    var prf: [String]?
}

struct RecapStatementBuilder {
    enum Errors: Error {
        case noActionsAuthorized
    }

    static func buildRecapStatement(recapUrn: RecapUrn) throws -> String {
            var statementParts: [String] = []
            var actionCounter = 1

            // Processing only the last URN.
            let decodedRecap = recapUrn.recapData

            guard let attValue = decodedRecap.att else { throw Errors.noActionsAuthorized }

            let sortedResourceKeys = attValue.keys.sorted()

            for resourceKey in sortedResourceKeys {
                guard let actions = attValue[resourceKey] else { continue }

                var groupedActions: [String: [String]] = [:]
                for actionType in actions.keys {
                    let prefix = String(actionType.split(separator: "/").first ?? "")
                    let action = actionType.split(separator: "/").dropFirst().joined(separator: ": ")
                    groupedActions[prefix, default: []].append(action)
                }

                for (prefix, actions) in groupedActions.sorted(by: { $0.key < $1.key }) {
                    let formattedActions = actions.sorted().map { "'\($0)'" }.joined(separator: ", ")
                    statementParts.append("(\(actionCounter)) '\(prefix)': \(formattedActions) for '\(resourceKey)'")
                    actionCounter += 1
                }
            }

            if statementParts.isEmpty {
                throw Errors.noActionsAuthorized
            } else {
                let formattedStatement = statementParts.joined(separator: ". ")
                return "I further authorize the stated URI to perform the following actions on my behalf: \(formattedStatement)."
            }
        }
}
