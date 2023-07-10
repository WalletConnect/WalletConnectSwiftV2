import SwiftUI

struct GetAWalletView: View {
    
    let wallets: [Listing]
    let onTap: (Listing) -> Void
    
    var body: some View {
        List {
            ForEach(wallets) { wallet in
                Button {
                    onTap(wallet)
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
        .frame(height: 500)
        .listStyle(.plain)
    }
}
