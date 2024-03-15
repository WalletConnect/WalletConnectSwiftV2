
import Foundation

struct SignRecap {
    struct RecapData: Codable {
        var att: [String: [String: [AnyCodable]]]?
        var prf: [String]?
    }
    let urn: String
    let recapData: RecapData

    enum Errors: Error {
        case invalidUrnPrefix
        case invalidRecapStructure
    }

    init(urn: String) throws {
        guard urn.hasPrefix("urn:recap") else {
            throw Errors.invalidUrnPrefix
        }

        let base64Part = urn.dropFirst("urn:recap:".count)
        guard let jsonData = Data(base64urlEncoded: String(base64Part)),
              let decodedData = try? JSONDecoder().decode(RecapData.self, from: jsonData) else {
            throw Errors.invalidRecapStructure
        }

        // Validate the structure specifically for 'eip155' with 'request/' prefixed actions
        guard let eip155Actions = decodedData.att?["eip155"], !eip155Actions.isEmpty else {
            throw Errors.invalidRecapStructure
        }

        self.urn = urn
        self.recapData = decodedData
    }

    var methods: Set<String> {
        guard let eip155Actions = recapData.att?["eip155"] else { return [] }
        return Set(eip155Actions.keys
            .filter { $0.hasPrefix("request/") }
            .map { String($0.dropFirst("request/".count)) })
    }
    var chains: [Blockchain] {
        guard let eip155Actions = recapData.att?["eip155"] else { return [] }

        // Attempt to find and decode the first action's chain array from AnyCodable
        if let firstActionKey = eip155Actions.keys.first,
           let firstActionValues = eip155Actions[firstActionKey],
           let firstActionValue = firstActionValues.first,
           let dict = try? firstActionValue.get([String:[String]].self),
           let chainsArray = dict["chains"]{
            return chainsArray.compactMap(Blockchain.init)
        }

        return []
    }

}

