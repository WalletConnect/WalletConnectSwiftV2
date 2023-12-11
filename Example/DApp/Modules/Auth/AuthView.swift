import SwiftUI

struct AuthView: View {
    @EnvironmentObject var presenter: AuthPresenter
    
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
                    
                    Spacer()
                }
            }
            .navigationTitle("Auth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(red: 25/255, green: 26/255, blue: 26/255),
                for: .navigationBar
            )
            .onAppear {
                presenter.onAppear()
            }
            .sheet(isPresented: $presenter.showSigningState) {
                ZStack {
                    Color(red: 25/255, green: 26/255, blue: 26/255)
                        .ignoresSafeArea()
                    
                    VStack {
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.gray.opacity(0.5))
                                .frame(width: 30, height: 4)
                            
                        }
                        .padding(20)
                        
                        Image("profile")
                            .resizable()
                            .frame(width: 64, height: 64)
                        
                        switch presenter.signingState {
                        case .error(let error):
                            Text(error.localizedDescription)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.green)
                                .cornerRadius(16)
                                .padding(.top, 16)
                            
                        case .signed(let cacao):
                            HStack {
                                Text(cacao.p.iss.split(separator: ":").last ?? "")
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(width: 135)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.91))
                                
                                Button {
                                    UIPasteboard.general.string = String(cacao.p.iss.split(separator: ":").last ?? "")
                                } label: {
                                    Image("copy")
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                }
                            }
                            
                            Text("Authenticated")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.green)
                                .cornerRadius(16)
                                .padding(.top, 16)
                            
                        case .none:
                            EmptyView()
                        }
                        
                        Spacer()
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}

