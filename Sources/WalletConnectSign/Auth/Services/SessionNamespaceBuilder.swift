
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

        guard let firstRecapResource = cacaos.first?.p.resources?.compactMap({ try? SignRecap(urn: $0) }).first else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        for cacao in cacaos {
            guard let resources = cacao.p.resources,
                  resources.contains(where: { (try? SignRecap(urn: $0)) != nil }) else {
                throw Errors.malformedRecap
            }
        }

        guard let chainsNamespace = try? DIDPKH(did: cacaos.first!.p.iss).account.blockchain.namespace else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let accounts = cacaos.compactMap { try? DIDPKH(did: $0.p.iss).account }
        let accountsSet = Set(accounts)
        let methods = firstRecapResource.methods
        let chains = firstRecapResource.chains
        let events: Set<String> = ["chainChanged", "accountsChanged"]

        guard !chains.isEmpty else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let sessionNamespace = SessionNamespace(chains: chains, accounts: accountsSet, methods: methods, events: events)
        return [chainsNamespace: sessionNamespace]
    }
}
