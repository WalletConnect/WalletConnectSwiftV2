import Foundation

struct Listing: Codable {
    struct ImageURL: Codable {
        @FailableDecodable
        private(set) var sm: URL?

        @FailableDecodable
        private(set) var md: URL?

        @FailableDecodable
        private(set) var lg: URL?
    }
    let id: String
    let name: String
    let description: String?
    let homepage: String?
    let image_url: ImageURL?
    let dapp_url: String
    let order: Int?
    let is_verified: Bool
    let is_featured: Bool
}
