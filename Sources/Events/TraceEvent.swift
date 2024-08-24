import Foundation

struct TraceEvent: Codable {
    struct Props: Codable {
        let event: String
        let type: String
        let properties: Properties?
    }

    struct Properties: Codable {
        let topic: String?
        let trace: [String]?
    }
    let eventId: String
    let bundleId: String
    let timestamp: Int64
    let props: Props
}

