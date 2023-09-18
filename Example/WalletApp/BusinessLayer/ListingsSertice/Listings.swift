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
    struct App: Codable {
        @FailableDecodable
        private(set) var ios: URL?

        @FailableDecodable
        private(set) var android: URL?

        @FailableDecodable
        private(set) var browser: URL?
    }
    struct Mobile: Codable {
        let native: String?
        let universal: String?
    }
    struct Metadata: Codable {
        struct Colors: Codable {
            let primary: String?
            let secondary: String?
        }
        let shortName: String
        let colors: Colors
    }
    let id: String
    let name: String
    let description: String
    let homepage: String
    let image_url: ImageURL
    let app: App
    let mobile: Mobile
    let metadata: Metadata
    let chains: [String]
}
