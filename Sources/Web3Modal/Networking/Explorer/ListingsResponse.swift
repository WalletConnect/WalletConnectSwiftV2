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
    let mobile: Mobile

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case homepage
        case order
        case imageId = "image_id"
        case app
        case mobile
    }

    struct App: Codable, Hashable {
        let ios: String?
        let mac: String?
        let safari: String?
    }
    
    struct Mobile: Codable, Hashable {
        let native: String?
        let universal: String?
    }
}
