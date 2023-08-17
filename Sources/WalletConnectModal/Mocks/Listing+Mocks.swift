import Foundation

#if DEBUG

extension Listing {
    static let stubList: [Listing] = [
        Listing(
            id: UUID().uuidString,
            name: "Sample Wallet",
            homepage: "https://example.com",
            order: 1,
            imageId: UUID().uuidString,
            app: Listing.App(
                ios: "https://example.com/download-ios",
                browser: "https://example.com/download-safari"
            ),
            mobile: .init(
                native: "sampleapp://deeplink",
                universal: "https://example.com/universal"
            ),
            desktop: .init(
                native: nil,
                universal: "https://example.com/universal"
            )
        ),
        Listing(
            id: UUID().uuidString,
            name: "Awesome Wallet",
            homepage: "https://example.com/awesome",
            order: 2,
            imageId: UUID().uuidString,
            app: Listing.App(
                ios: "https://example.com/download-ios",
                browser: "https://example.com/download-safari"
            ),
            mobile: .init(
                native: "awesomeapp://deeplink",
                universal: "https://example.com/awesome/universal"
            ),
            desktop: .init(
                native: nil,
                universal: "https://example.com/awesome/universal"
            )
        ),
        Listing(
            id: UUID().uuidString,
            name: "Cool Wallet",
            homepage: "https://example.com/cool",
            order: 3,
            imageId: UUID().uuidString,
            app: Listing.App(
                ios: "https://example.com/download-ios",
                browser: "https://example.com/download-safari"
            ),
            mobile: .init(
                native: "coolapp://deeplink",
                universal: "https://example.com/cool/universal"
            ),
            desktop: .init(
                native: nil,
                universal: "https://example.com/cool/universal"
            )
        )
    ]
}

#endif
