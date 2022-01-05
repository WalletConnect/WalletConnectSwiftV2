struct PairingApproval: Codable, Equatable {
    let relay: RelayProtocolOptions
    let responder: Participant
    let expiry: Int
    let state: PairingState?
}
