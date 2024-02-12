import Foundation

public struct AuthPayload: Codable, Equatable {
    public let domain: String
    public let aud: String
    public let version: String
    public let nonce: String
    public let chains: [String]
    public let type: String
    public let iat: String
    public let nbf: String?
    public let exp: String?
    public let statement: String?
    public let requestId: String?
    public let resources: [String]?

    internal init(
        domain: String,
        aud: String,
        version: String,
        nonce: String,
        chains: [String],
        type: String,
        iat: String,
        nbf: String? = nil,
        exp: String? = nil,
        statement: String? = nil,
        requestId: String? = nil,
        resources: [String]? = nil
    ) {
        self.domain = domain
        self.aud = aud
        self.version = version
        self.nonce = nonce
        self.chains = chains
        self.type = type
        self.iat = iat
        self.nbf = nbf
        self.exp = exp
        self.statement = statement
        self.requestId = requestId
        self.resources = resources
    }


    init(requestParams: AuthRequestParams, iat: String) {
        self.type = "caip122"
        self.chains = requestParams.chains
        self.domain = requestParams.domain
        self.aud = requestParams.aud
        self.version = "1"
        self.nonce = requestParams.nonce
        self.iat = iat
        self.nbf = requestParams.nbf
        self.exp = requestParams.exp
        self.statement = requestParams.statement
        self.requestId = requestParams.requestId
        self.resources = requestParams.resources
    }

    func cacaoPayload(account: Account) throws -> CacaoPayload {
        return CacaoPayload(
            iss: account.did,
            domain: domain,
            aud: aud,
            version: version,
            nonce: nonce,
            iat: iat,
            nbf: nbf,
            exp: exp,
            statement: statement,
            requestId: requestId,
            resources: resources
        )
    }
}



public struct AuthPayloadBuilder {

    public static func build(request: AuthPayload, supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> AuthPayload {
        // Attempt to find a valid session recap URN from the resources
        guard let existingSessionRecapUrn = request.resources?.first(where: { (try? SessionRecap(urn: $0)) != nil }) else {
            throw SessionRecap.Errors.invalidRecapStructure
        }

        // Use SessionRecapBuilder to create a new session recap based on the existing valid URN
        let newSessionRecap = try SessionRecapBuilder.build(requestedSessionRecap: existingSessionRecapUrn, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)

        // Encode the new session recap to its URN format
        let newSessionRecapUrn = newSessionRecap.urn

        // Filter out the old session recap URNs, retaining all other resources
        let updatedResources = request.resources?.filter { (try? SessionRecap(urn: $0)) == nil }

        // Add the new session recap URN to the updated resources
        let finalResources = (updatedResources ?? []) + [newSessionRecapUrn]

        // Return a new AuthPayload with the updated resources
        return AuthPayload(
            domain: request.domain,
            aud: request.aud,
            version: request.version,
            nonce: request.nonce,
            chains: request.chains,
            type: request.type,
            iat: request.iat,
            nbf: request.nbf,
            exp: request.exp,
            statement: request.statement,
            requestId: request.requestId,
            resources: finalResources
        )
    }
}
