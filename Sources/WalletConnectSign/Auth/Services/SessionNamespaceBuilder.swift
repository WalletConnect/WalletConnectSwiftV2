
import Foundation

class SessionNamespaceBuilder {
    enum Errors: Error {
        case emptyCacaosArrayForbidden
        case cannotCreateSessionNamespaceFromTheRecap
        case malformedRecap
    }
    private let logger: ConsoleLogging

    init(logger: ConsoleLogging) {
        self.logger = logger
    }

    func buildSessionNamespaces(cacaos: [Cacao]) throws -> [String: SessionNamespace] {
        guard !cacaos.isEmpty else {
            throw Errors.emptyCacaosArrayForbidden
        }

        // Attempt to initialize SessionRecapUrn from the first valid recap URN in the resources
        guard let firstRecapResource = cacaos.first?.p.resources?.compactMap({ try? SessionRecap(urn: $0) }).first else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        // Validate that all cacaos contain an equivalent SessionRecapUrn resource
        for cacao in cacaos {
            guard let resources = cacao.p.resources,
                  resources.contains(where: { (try? SessionRecap(urn: $0)) != nil }) else {
                throw Errors.malformedRecap
            }
        }

        guard let chainsNamespace = try? DIDPKH(did: cacaos.first!.p.iss).account.blockchain.namespace else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let accounts = cacaos.compactMap { try? DIDPKH(did: $0.p.iss).account }

        let accountsSet = Set(accounts)
        let methods = firstRecapResource.methods

        let sessionNamespace = SessionNamespace(accounts: accountsSet, methods: methods, events: [])
        return [chainsNamespace: sessionNamespace]
    }
}
