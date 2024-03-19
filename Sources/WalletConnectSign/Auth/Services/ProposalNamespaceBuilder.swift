
import Foundation

struct ProposalNamespaceBuilder {

    enum Errors: Error {
        case unsupportedChain
    }

    static func buildNamespace(from params: AuthRequestParams) throws -> [String: ProposalNamespace] {
        var methods = Set(params.methods ?? [])
        if methods.isEmpty {
            methods = ["personal_sign"]
        }
        let chains: [Blockchain] = params.chains.compactMap { Blockchain($0) }
        guard chains.allSatisfy({$0.namespace == "eip155"}) else {
            throw Errors.unsupportedChain
        }
        return [
            "eip155": ProposalNamespace(
                chains: chains,
                methods: methods,
                events: ["chainChanged", "accountsChanged"]
            )]
    }
}
