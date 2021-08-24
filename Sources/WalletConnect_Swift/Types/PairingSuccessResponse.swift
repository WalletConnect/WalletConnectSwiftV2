// 

import Foundation

struct AppMetadata: Codable, Equatable {
  let name: String?
  let description: String?
  let url: String?
  let icons: [String]?
}

struct PairingState: Codable, Equatable {
  let metadata: AppMetadata
}

struct PairingParticipant:Codable, Equatable {
  let publicKey: String
}
