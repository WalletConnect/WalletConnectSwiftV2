import Foundation

public struct Participant: Codable, Equatable {
    public let publicKey: String
    let metadata: AppMetadata

    init(publicKey: String, metadata: AppMetadata) {
        self.publicKey = publicKey
        self.metadata = metadata
    }
}

struct AgreementPeer: Codable, Equatable {
    let publicKey: String
}
