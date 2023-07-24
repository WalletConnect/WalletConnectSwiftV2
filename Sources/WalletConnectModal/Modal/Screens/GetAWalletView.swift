import SwiftUI

struct GetAWalletView: View {
    let wallets: [Listing]
    let onWalletTap: (Listing) -> Void
    let navigateToExternalLink: (URL) -> Void
    
    var body: some View {
        ScrollView {
            List {
                ForEach(wallets, id: \.id) { wallet in
                    Button {
                        onWalletTap(wallet)
                    } label: {
                        HStack {
                            WalletImage(wallet: wallet)
                                .frame(width: 40, height: 40)
                            
                            Text(wallet.name)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(.footnote).weight(.semibold))
                        }
                    }
                }
            }
            .frame(minHeight: 400)
            .listStyle(.plain)
            
            VStack(alignment: .center, spacing: 8) {
                Text("Not what you’re looking for?")
                    .font(
                        .system(size: 16)
                        .weight(.semibold)
                    )
                    .multilineTextAlignment(.center)
                    .foregroundColor(.foreground1)
                
                Text("With hundreds of wallets out there, there’s something for everyone ")
                    .font(
                        .system(size: 14)
                        .weight(.medium)
                    )
                    .foregroundColor(.foreground2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(action: {
                    navigateToExternalLink(URL(string: "https://walletconnect.com/explorer?type=wallet")!)
                }) {
                    HStack {
                        Text("Explore Wallets")
                        Image(.external_link)
                    }
                }
                .buttonStyle(WCMMainButtonStyle())
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 0)
            .padding(.top, 0)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

#if DEBUG

struct GetAWalletView_Previews: PreviewProvider {
    static var previews: some View {
        GetAWalletView(
            wallets: Listing.stubList,
            onWalletTap: { _ in },
            navigateToExternalLink: { _ in }
        )
        .environment(\.projectId, Secrets.load().projectID)
    }
}

#endif
