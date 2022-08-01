
import Foundation
import WalletConnectUtils

struct AuthRequestParams: Codable, Equatable {
    let requester: Requester
    let payloadParams: AuthPayload

    static var tag: Int {
        return 3000
    }
}

extension AuthRequestParams {
    struct Requester: Codable, Equatable {
        let publicKey: String
        let metadata: AppMetadata
    }
}

// TODO - temporarly duplicated - moved do utils in concurrent PR
public struct AppMetadata: Codable, Equatable {
    public let name: String
    public let description: String
    public let url: String
    public let icons: [String]
    public init(name: String, description: String, url: String, icons: [String]) {
        self.name = name
        self.description = description
        self.url = url
        self.icons = icons
    }
}
