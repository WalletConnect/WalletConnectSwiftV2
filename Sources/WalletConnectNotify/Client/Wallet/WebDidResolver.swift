
import Foundation

class WebDidResolver {

    enum Errors: Error {
        case invalidUrl
    }

    func resolveDidDoc(domainUrl: String) async throws -> WebDidDoc {
        guard let didDocUrl = URL(string: "\(domainUrl)/.well-known/did.json") else { throw Errors.invalidUrl }
        let (data, _) = try await URLSession.shared.data(from: didDocUrl)
        return try JSONDecoder().decode(WebDidDoc.self, from: data)
    }
}
