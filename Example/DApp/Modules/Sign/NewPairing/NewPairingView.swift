import SwiftUI

import WalletConnectSign

struct NewPairingView: View {
    @EnvironmentObject var presenter: NewPairingPresenter
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 25/255, green: 26/255, blue: 26/255)
                    .ignoresSafeArea()
                
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.white)
                            .aspectRatio(1, contentMode: .fit)
                            .padding(20)
                        
                        if let data = presenter.qrCodeImageData {
                            let qrCodeImage = UIImage(data: data) ?? UIImage()
                            Image(uiImage: qrCodeImage)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .padding(40)
                        }
                    }
                    
                    Button {
                        presenter.connectWallet()
                    } label: {
                        Text("Connect Sample Wallet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(red: 95/255, green: 159/255, blue: 248/255))
                            .cornerRadius(16)
                    }
                    
                    Button {
                        presenter.copyUri()
                    } label: {
                        HStack {
                            Image("copy")
                            Text("Copy link")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                        }
                    }
                    .padding(.top, 16)
                    
                    Text(presenter.walletConnectUri.absoluteString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                        .opacity(0)
                    
                    Spacer()
                }
            }
            .navigationTitle("New Pairing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(red: 25/255, green: 26/255, blue: 26/255),
                for: .navigationBar
            )
            .toolbarRole(.editor)
            .onAppear {
                presenter.onAppear()
            }
        }
    }
}

// MARK: - Previews
struct SignNewPairingView_Previews: PreviewProvider {
    static var previews: some View {
        NewPairingView()
    }
}
