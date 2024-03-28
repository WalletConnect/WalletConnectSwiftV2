
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

        let chains = firstRecapResource.chains
        guard !chains.isEmpty else {
            throw Errors.cannotCreateSessionNamespaceFromTheRecap
        }

        let addresses = getUniqueAddresses(from: cacaos)
        var accounts = [Account]()

        for address in addresses {
            for chain in chains {
                if let account = Account(blockchain: chain, address: address) {
                    accounts.append(account)
                }
            }
        }

        let methods = firstRecapResource.methods
        let events: Set<String> = ["chainChanged", "accountsChanged"]

        let sessionNamespace = SessionNamespace(chains: chains, accounts: accounts, methods: methods, events: events)
        return [chainsNamespace: sessionNamespace]
    }

    func getUniqueAddresses(from cacaos: [Cacao]) -> [String] {
        var seenAddresses = Set<String>()
        var uniqueAddresses = [String]()

        for cacao in cacaos {
            if let address = try? DIDPKH(did: cacao.p.iss).account.address, !seenAddresses.contains(address) {
                uniqueAddresses.append(address)
                seenAddresses.insert(address)
            }
        }
        return uniqueAddresses
    }

}
