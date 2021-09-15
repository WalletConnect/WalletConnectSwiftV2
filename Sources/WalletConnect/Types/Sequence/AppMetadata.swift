
import Foundation

public struct AppMetadata: Codable, Equatable {
    public init(name: String?, description: String?, url: String?, icons: [String]?) {
        self.name = name
        self.description = description
        self.url = url
        self.icons = icons
    }
    
    let name: String?
    let description: String?
    let url: String?
    let icons: [String]?
}
