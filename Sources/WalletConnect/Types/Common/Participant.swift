struct Participant: Codable, Equatable {
    let metadata: AppMetadata?
    
    init(metadata: AppMetadata? = nil) {
        self.metadata = metadata
    }
}

struct PairingParticipant: Codable, Equatable {
    let publicKey: String
}

struct SessionParticipant: Codable, Equatable {
    let publicKey: String
    let metadata: AppMetadata
}
