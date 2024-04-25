import Foundation

public class RecapUrnMergingService {
    public enum Errors: Error {
        case emptyRecapUrns
        case encodingFailed
    }

    public static func merge(recapUrns: [RecapUrn]) throws -> RecapUrn {
        guard !recapUrns.isEmpty else {
            throw Errors.emptyRecapUrns
        }

        // If there's only one URN, return it directly.
        if recapUrns.count == 1 {
            return recapUrns.first!
        }

        var mergedAtt: [String: [String: [AnyCodable]]] = [:]

        // Aggregate all actions under their respective keys
        for recapUrn in recapUrns {
            guard let att = recapUrn.recapData.att else { continue }
            for (key, value) in att {
                if var existingValue = mergedAtt[key] {
                    for (actionKey, actionValue) in value {
                        existingValue[actionKey] = (existingValue[actionKey] ?? []) + actionValue
                    }
                    mergedAtt[key] = existingValue
                } else {
                    mergedAtt[key] = value
                }
            }
        }

        // Sort and then ensure actions are also sorted, if necessary.
        let sortedMergedAtt = mergedAtt
            .sorted { $0.key < $1.key }
            .reduce(into: [String: [String: [AnyCodable]]]()) { (result, pair) in
                let (resource, actions) = pair
                let sortedActions = actions
                    .sorted { $0.key < $1.key }
                    .reduce(into: [String: [AnyCodable]]()) { (actionsResult, actionPair) in
                        actionsResult[actionPair.key] = actionPair.value
                    }
                result[resource] = sortedActions
            }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let jsonData = try? encoder.encode(RecapData(att: sortedMergedAtt, prf: nil)),
              let jsonBase64 = jsonData.base64urlEncodedString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            throw Errors.encodingFailed
        }

        let mergedUrnString = "urn:recap:\(jsonBase64)"
        return try RecapUrn(urn: mergedUrnString)
    }
}
