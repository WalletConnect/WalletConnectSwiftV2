//     

import Foundation

struct ProposalNamespaceBuilder {

    enum Errors: Error {
        case unsupportedChain
    }

    static func buildNamespace(from params: AuthRequestParams) throws -> [String: ProposalNamespace] {
        let chains: Set<Blockchain> = Set(params.chains.compactMap { Blockchain($0) })
        guard chains.allSatisfy({$0.namespace == "eip155"}) else {
            throw Errors.unsupportedChain
        }
        let methods = Set(params.methods ?? [])
        return [
            "eip155": ProposalNamespace(
                chains: chains,
                methods: methods,
                events: []
            )]
    }
}
