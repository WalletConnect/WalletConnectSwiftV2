import Foundation

public struct WalletClientOptions {
    let apiKey: String
    let name: String
    let isController: Bool
    let metadata: AppMetadata
    let relayURL: URL
}
