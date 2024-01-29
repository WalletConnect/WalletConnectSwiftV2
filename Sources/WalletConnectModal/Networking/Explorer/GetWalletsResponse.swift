import Foundation

struct GetWalletsResponse: Codable {
    let count: Int
    let data: [Wallet]
}

class Wallet: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let homepage: String
    let imageId: String
    let order: Int
    let mobileLink: String?
    let desktopLink: String?
    let webappLink: String?
    let appStore: String?
    
    var lastTimeUsed: Date?
    var isInstalled: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case homepage
        case imageId = "image_id"
        case order
        case mobileLink = "mobile_link"
        case desktopLink = "desktop_link"
        case webappLink = "webapp_link"
        case appStore = "app_store"
        
        // Decorated
        case lastTimeUsed
        case isInstalled
    }
    
    init(
        id: String,
        name: String,
        homepage: String,
        imageId: String,
        order: Int,
        mobileLink: String? = nil,
        desktopLink: String? = nil,
        webappLink: String? = nil,
        appStore: String? = nil,
        lastTimeUsed: Date? = nil,
        isInstalled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.homepage = homepage
        self.imageId = imageId
        self.order = order
        self.mobileLink = mobileLink
        self.desktopLink = desktopLink
        self.webappLink = webappLink
        self.appStore = appStore
        self.lastTimeUsed = lastTimeUsed
        self.isInstalled = isInstalled
    }
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.homepage = try container.decode(String.self, forKey: .homepage)
        self.imageId = try container.decode(String.self, forKey: .imageId)
        self.order = try container.decode(Int.self, forKey: .order)
        self.mobileLink = try container.decodeIfPresent(String.self, forKey: .mobileLink)
        self.desktopLink = try container.decodeIfPresent(String.self, forKey: .desktopLink)
        self.webappLink = try container.decodeIfPresent(String.self, forKey: .webappLink)
        self.appStore = try container.decodeIfPresent(String.self, forKey: .appStore)
        self.lastTimeUsed = try container.decodeIfPresent(Date.self, forKey: .lastTimeUsed)
        self.isInstalled = try container.decodeIfPresent(Bool.self, forKey: .isInstalled) ?? false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
        
    static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}
