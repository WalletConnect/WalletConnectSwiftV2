import Foundation

struct ListingsResponse: Codable {
    let listings: [String: Listing]
}

class Listing: Codable, Hashable, Identifiable {
    init(
        id: String, 
        name: String, 
        homepage: String, 
        order: Int? = nil, 
        imageId: String, 
        app: Listing.App, 
        mobile: Listing.Links,
        desktop: Listing.Links,
        lastTimeUsed: Date? = nil,
        installed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.homepage = homepage
        self.order = order
        self.imageId = imageId
        self.app = app
        self.mobile = mobile
        self.desktop = desktop
        self.lastTimeUsed = lastTimeUsed
        self.installed = installed
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    static func == (lhs: Listing, rhs: Listing) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    let id: String
    let name: String
    let homepage: String
    let order: Int?
    let imageId: String
    let app: App
    let mobile: Links
    let desktop: Links
    
    var lastTimeUsed: Date?
    var installed: Bool = false

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
