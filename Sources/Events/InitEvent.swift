
import Foundation

struct InitEvent: Codable {
    struct Props: Codable {
        let event: String = "INIT"
        let type: String = "None"
        let properties: Properties
    }

    struct Properties: Codable {
        let clientId: String
        let userAgent: String

        // Custom CodingKeys to map Swift property names to JSON keys
        enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
            case userAgent = "user_agent"
        }
    }

    let eventId: String
    let bundleId: String
    let timestamp: Int64
    let props: Props
}
