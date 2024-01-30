import SwiftUI

struct WalletImage: View {
    
    enum Size: String {
        case small = "sm"
        case medium = "md"
        case large = "lg"
    }
    
    @Environment(\.projectId) var projectId
    
    var wallet: Wallet?
    var size: Size = .medium
    
    var body: some View {
        
        AsyncImage(url: imageURL(for: wallet)) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Color.foreground3
        }
    }
    
    private func imageURL(for wallet: Wallet?) -> URL? {
        
        guard let wallet else { return nil }
            
        let urlString = "https://explorer-api.walletconnect.com/v3/logo/\(size.rawValue)/\(wallet.imageId)?projectId=\(projectId)"
            
        return URL(string: urlString)
    }
}
