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

#if DEBUG

extension Listing {
    static let stubList: [Listing] = [
        Listing(id: UUID().uuidString, name: "Sample Wallet", homepage: "https://example.com", order: 1, imageId: UUID().uuidString, app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "sampleapp://deeplink", universal: "https://example.com/universal")),
        Listing(id: UUID().uuidString, name: "Awesome Wallet", homepage: "https://example.com/awesome", order: 2, imageId: UUID().uuidString, app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "awesomeapp://deeplink", universal: "https://example.com/awesome/universal")),
        Listing(id: UUID().uuidString, name: "Cool Wallet", homepage: "https://example.com/cool", order: 3, imageId: UUID().uuidString, app: Listing.App(ios: "https://example.com/download-ios", mac: "https://example.com/download-mac", safari: "https://example.com/download-safari"), mobile: Listing.Mobile(native: "coolapp://deeplink", universal: "https://example.com/cool/universal"))
    ]
}

#endif
