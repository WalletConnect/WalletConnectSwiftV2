// 

import Foundation

struct AppMetadata {
  let name: String
  let description: String
  let url: String
  let icons: [String]
}

struct PairingState {
  let metadata: AppMetadata
}

struct PairingParticipant {
  let publicKey: String
}

struct PairingSuccessResponse {
  let topic: String
  let relay: RelayProtocolOptions
  let responder: PairingParticipant
  let expiry: Int
  let state: PairingState?
}
