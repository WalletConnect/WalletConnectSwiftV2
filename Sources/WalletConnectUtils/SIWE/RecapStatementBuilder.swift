
import Foundation

struct RecapStatementBuilder {
    static func buildRecapStatement(from decodedRecap: [String: [String: [String]]]) -> String {
        var statementParts: [String] = []

        // sort resources keys for consistancy in the statement
        let sortedResourceKeys = decodedRecap.keys.sorted()

        for resourceKey in sortedResourceKeys {
            guard let actions = decodedRecap[resourceKey] else { continue }
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

        if !statementParts.isEmpty {
            let formattedStatement = statementParts.joined(separator: "; ")
            return "I further authorize the stated URI to perform the following actions: (1) \(formattedStatement)."
        } else {
            return ""
        }
    }
}
