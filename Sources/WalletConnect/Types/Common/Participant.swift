// TODO: need different for pair and session
struct Participant: Codable, Equatable {
    let publicKey: String
    let metadata: AppMetadata?
    
    init(publicKey: String, metadata: AppMetadata? = nil) {
        self.publicKey = publicKey
        self.metadata = metadata
    }
}
