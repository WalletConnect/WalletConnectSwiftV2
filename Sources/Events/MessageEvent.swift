
import Foundation

struct MessageEvent: Codable {
    struct Props: Codable {
        let event: String = "SUCCESS"
        let type: String
        let properties: Properties
    }

    struct Properties: Codable {
        let correlationId: Int64
        let clientId: String
        let direction: Direction

        // Custom CodingKeys to map Swift property names to JSON keys
        enum CodingKeys: String, CodingKey {
            case correlationId = "correlation_id"
            case clientId = "client_id"
            case direction
        }
    }

    enum Direction: String, Codable {
        case sent
        case received
    }

    let eventId: String
    let bundleId: String
    let timestamp: Int64
    let props: Props
}
