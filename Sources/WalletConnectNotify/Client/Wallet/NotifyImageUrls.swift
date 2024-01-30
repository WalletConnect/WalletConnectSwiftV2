import Foundation

public struct NotifyImageUrls: Codable, Equatable {

    public let sm: String?
    public let md: String?
    public let lg: String?

    public init(sm: String? = nil, md: String? = nil, lg: String? = nil) {
        self.sm = sm
        self.md = md
        self.lg = lg
    }

    public init?(icons: [String]) {
        guard icons.count == 3 else { return nil }
        self.sm = icons[0]
        self.md = icons[1]
        self.lg = icons[2]
    }
}
