import Foundation

struct ListingsResponse: Codable {
    let listings: [String: Listing]
}

struct Listing: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let homepage: String
    let order: Int?
    let imageId: String
    let app: App
    let mobile: Links
    let desktop: Links
    var lastTimeUsed: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case homepage
        case order
        case imageId = "image_id"
        case app
        case mobile
        case desktop
        case lastTimeUsed
    }

    struct App: Codable, Hashable {
        let ios: String?
        let browser: String?
    }
    
    struct Links: Codable, Hashable {
        let native: String?
        let universal: String?
    }
}
