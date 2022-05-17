
import Foundation

/**
 A structure that identifies a peer connected through a WalletConnect session.
 
 You can provide human-readable information about your app so that it can be shared with a connected peer, for example,
 during a session proposal event.
 
 This information should make the identity of your app clear to the end-user and easily verifiable. Therefore, it is a
 suitable place to briefly communicate your brand.
 */
public struct AppMetadata: Codable, Equatable {
    
    /// The name of the app.
    public let name: String
    
    /// A brief textual description of the app that can be displayed to peers.
    public let description: String
    
    /// The URL string that identifies the official domain of the app.
    public let url: String
    
    /// An array of URL strings pointing to the icon assets on the web.
    public let icons: [String]
    
    /**
     Creates a new metadata object with the specified information.
     
     - parameters:
        - name: The name of the app.
        - description: A brief textual description of the app that can be displayed to peers.
        - url: The URL string that identifies the official domain of the app.
        - icons: An array of URL strings pointing to the icon assets on the web.
     */
    public init(name: String, description: String, url: String, icons: [String]) {
        self.name = name
        self.description = description
        self.url = url
        self.icons = icons
    }
}
