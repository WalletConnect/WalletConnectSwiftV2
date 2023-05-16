import SwiftUI

struct WhatIsWalletView: View {
    
    var body: some View {
        
        VStack(spacing: 10) {
            HelpSection(
                title: "A home for your digital assets",
                description: "A wallet lets you store, send and receive digital assets like cryptocurrencies and NFTs.",
                assets: ["DeFi", "NFT", "ETH"]
            )
            HelpSection(
                title: "One login for all of web3",
                description: "Log in to any app by connecting your wallet. Say goodbye to countless passwords!",
                assets: ["Login", "Profile", "Lock"]
            )
            HelpSection(
                title: "Your gateway to a new web",
                description: "With your wallet, you can explore and interact with DeFi, NFTs, DAOs, and much more.",
                assets: ["Browser", "Noun", "DAO"]
            )
            
            HStack {
                Button(action: {}) {
                    HStack {
                        Image("wallet", bundle: .module)
                        Text("Get a Wallet")
                    }
                }
                Button(action: {}) {
                    HStack {
                        Text("Learn More")
                        Image("external_link", bundle: .module)
                    }
                }
            }
            .buttonStyle(W3MButtonStyle())
        }
        .padding(34)
    }
}

extension Color {
    static let foreground1 = Color(red: 20/255, green: 20/255, blue: 20/255)
    static let foreground2 = Color(red: 121/255, green: 134/255, blue: 134/255)
    
    static let blueDark = Color(red: 71/255, green: 161/255, blue: 255/255)
}

struct HelpSection: View {
    
    let title: String
    let description: String
    let assets: [String]
    
    var body: some View {
        VStack {
            HStack {
                ForEach(assets, id: \.self) { asset in
                    Image(asset, bundle: .module)
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
        }
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
}

struct WhatIsWalletView_Previews: PreviewProvider {
    
    static var previews: some View {
        
        WhatIsWalletView()
    }
}

struct W3MButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.blueDark)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}
