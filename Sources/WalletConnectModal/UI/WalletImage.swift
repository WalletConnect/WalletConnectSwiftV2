import SwiftUI

struct WalletImage: View {
    
    enum Size: String {
        case small = "sm"
        case medium = "md"
        case large = "lg"
    }
    
    @Environment(\.projectId) var projectId
    
    var wallet: Listing?
    var size: Size = .medium
    
    var body: some View {
        
        AsyncImage(url: imageURL(for: wallet)) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Color.foreground3
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.gray.opacity(0.4), lineWidth: 1)
        )
    }
    
    private func imageURL(for wallet: Listing?) -> URL? {
        
        guard let wallet else { return nil }
            
        let urlString = "https://explorer-api.walletconnect.com/v3/logo/\(size.rawValue)/\(wallet.imageId)?projectId=\(projectId)"
            
        return URL(string: urlString)
    }
}
