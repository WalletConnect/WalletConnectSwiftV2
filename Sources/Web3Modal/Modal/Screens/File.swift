import SwiftUI

struct GetAWalletView: View {
    
    let wallets: [Listing]
    
    init(wallets: [Listing]) {
        self.wallets = wallets
        
        UITableView.appearance().backgroundColor = .clear // tableview background
        UITableViewCell.appearance().backgroundColor = .clear // cell background
    }
    
    var body: some View {
        List {
            ForEach(wallets) { wallet in
                Button {
                    print("foo")
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
