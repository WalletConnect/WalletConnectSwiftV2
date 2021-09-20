import Foundation

public struct WalletClientOptions {
    public init(apiKey: String, name: String, isController: Bool, metadata: AppMetadata, relayURL: URL) {
        self.apiKey = apiKey
        self.name = name
        self.isController = isController
        self.metadata = metadata
        self.relayURL = relayURL
    }
    
    let apiKey: String
    let name: String
    let isController: Bool
    let metadata: AppMetadata
    let relayURL: URL
}
