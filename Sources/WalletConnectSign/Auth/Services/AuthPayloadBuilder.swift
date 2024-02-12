
import Foundation


public struct AuthPayloadBuilder {

    public static func build(payload: AuthPayload, supportedEVMChains: [Blockchain], supportedMethods: [String]) throws -> AuthPayload {
        // Attempt to find a valid session recap URN from the resources
        guard let existingSessionRecapUrn = payload.resources?.first(where: { (try? SessionRecap(urn: $0)) != nil }) else {
            throw SessionRecap.Errors.invalidRecapStructure
        }

        // Use SessionRecapBuilder to create a new session recap based on the existing valid URN
        let newSessionRecap = try SessionRecapBuilder.build(requestedSessionRecap: existingSessionRecapUrn, supportedEVMChains: supportedEVMChains, supportedMethods: supportedMethods)

        // Encode the new session recap to its URN format
        let newSessionRecapUrn = newSessionRecap.urn

        // Filter out the old session recap URNs, retaining all other resources
        let updatedResources = payload.resources?.filter { (try? SessionRecap(urn: $0)) == nil }

        // Add the new session recap URN to the updated resources
        let finalResources = (updatedResources ?? []) + [newSessionRecapUrn]

        // Return a new AuthPayload with the updated resources
        return AuthPayload(
            domain: payload.domain,
            aud: payload.aud,
            version: payload.version,
            nonce: payload.nonce,
            chains: payload.chains,
            type: payload.type,
            iat: payload.iat,
            nbf: payload.nbf,
            exp: payload.exp,
            statement: payload.statement,
            requestId: payload.requestId,
            resources: finalResources
        )
    }
}
