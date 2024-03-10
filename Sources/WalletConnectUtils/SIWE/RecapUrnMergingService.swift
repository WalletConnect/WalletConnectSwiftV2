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

        if recapUrns.count == 1 {
            return recapUrns.first!
        }

        var mergedAtt: [String: [String: [AnyCodable]]] = [:]

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

        // Assuming RecapData can be encoded back to JSON and then to a Base64 string
        let mergedData = RecapData(att: mergedAtt, prf: nil)
        guard let jsonData = try? JSONEncoder().encode(mergedData),
              let jsonBase64 = jsonData.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            throw Errors.encodingFailed
        }

        let mergedUrnString = "urn:recap:\(jsonBase64)"
        return try RecapUrn(urn: mergedUrnString)
    }
}
