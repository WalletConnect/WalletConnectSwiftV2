import SwiftUI

struct WhatIsWalletView: View {
    
    var navigateTo: (Destination) -> Void
    var navigateToExternalLink: (URL) -> Void
    
    var body: some View {
        
        VStack(spacing: 10) {
            HelpSection(
                title: "A home for your digital assets",
                description: "A wallet lets you store, send and receive digital assets like cryptocurrencies and NFTs.",
                assets: [.DeFi, .NFT, .ETH]
            )
            HelpSection(
                title: "One login for all of web3",
                description: "Log in to any app by connecting your wallet. Say goodbye to countless passwords!",
                assets: [.Login, .Profile, .Lock]
            )
            HelpSection(
                title: "Your gateway to a new web",
                description: "With your wallet, you can explore and interact with DeFi, NFTs, DAOs, and much more.",
                assets: [.Browser, .Noun, .DAO]
            )
            
            HStack {
                Button(action: {
                    navigateTo(.getWallet)
                }) {
                    HStack {
                        Image(.wallet)
                        Text("Get a Wallet")
                    }
                }
                Button(action: {
                    navigateToExternalLink(URL(string: "https://ethereum.org/en/wallets/")!)
                }) {
                    HStack {
                        Text("Learn More")
                        Image(.external_link)
                    }
                }
            }
            .buttonStyle(W3MButtonStyle())
        }
        .padding(.horizontal, 24)
    }
}

struct HelpSection: View {
    
    let title: String
    let description: String
    let assets: [Asset]
    
    var body: some View {
        VStack {
            HStack {
                ForEach(assets, id: \.self) { asset in
                    Image(asset)
                }
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.foreground1)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.foreground2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct WhatIsWalletView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        WhatIsWalletView(navigateTo: { _ in}, navigateToExternalLink: { _ in })
    }
}
