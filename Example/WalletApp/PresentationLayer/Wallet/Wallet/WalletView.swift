import SwiftUI
import Web3Wallet

struct WalletView: View {
    @EnvironmentObject var presenter: WalletPresenter
    
    var body: some View {
        ZStack {
            Color.grey100
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    if presenter.sessions.isEmpty {
                        VStack(spacing: 10) {
                            Image("connect-template")
                            
                            Text("Apps you connect with will appear here. To connect scan or paste the code that’s displayed in the app.")
                                .foregroundColor(.grey50)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(20)
                    }
                    
                    VStack {
                        ZStack {
                            if !presenter.sessions.isEmpty {
                                List {
                                    ForEach(presenter.sessions, id: \.topic) { session in
                                        connectionView(session: session)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0))
                                    }
                                    .onDelete { indexSet in
                                        Task(priority: .high) {
                                            try await presenter.removeSession(at: indexSet)
                                        }
                                    }
                                }
                                .listStyle(PlainListStyle())
                            }
                            
                            if presenter.showPairingLoading {
                                VStack {
                                    Spacer()
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 20).fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    .blue100,
                                                    .blue200
                                                ]),
                                                startPoint: .top, endPoint: .bottom)
                                        )
                                        .blink()
                                        
                                        Text("WalletConnect is pairing...")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 15)
                                    }
                                    .fixedSize(horizontal: true, vertical: true)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Spacer()
                            
                            Button {
                                presenter.onPasteUri()
                            } label: {
                                Image("copy")
                                    .resizable()
                                    .frame(width: 56, height: 56)
                            }
                            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                            .accessibilityIdentifier("copy")
                            
                            Button {
                                presenter.onScanUri()
                            } label: {
                                Image("scan")
                                    .resizable()
                                    .frame(width: 56, height: 56)
                            }
                            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 20)
        }
        .alert(presenter.errorMessage, isPresented: $presenter.showError) {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $presenter.showConnectedSheet) {
            ZStack {
                VStack {
                    Image("connected")
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 48, height: 4)
                        .background(Color(red: 0.02, green: 0.17, blue: 0.17).opacity(0.2))
                        .cornerRadius(100)
                        .padding(.top, 8)
                    
                    Text("Connected")
                        .foregroundColor(.grey8)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .padding(.top, 168)
                    
                    
                    Text("You can go back to your browser now")
                        .foregroundColor(Color(red: 0.47, green: 0.53, blue: 0.53))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            presenter.onAppear()
        }
    }
    
    private func connectionView(session: Session) -> some View {
        Button {
            presenter.onConnection(session: session)
        } label: {
            VStack {
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: session.peer.icons.first ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .frame(width: 60, height: 60)
                                .background(Color.black)
                                .cornerRadius(30, corners: .allCorners)
                        } else {
                            Color.black
                                .frame(width: 60, height: 60)
                                .cornerRadius(30, corners: .allCorners)
                        }
                    }
                    .padding(.leading, 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.peer.name)
                            .foregroundColor(.grey8)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        
                        Text(session.peer.url)
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    
                    Spacer()
                    
                    Image("forward-shevron")
                        .foregroundColor(.grey8)
                        .padding(.trailing, 20)
                }
            }
        }
    }
}

#if DEBUG
struct WalletView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView()
    }
}
#endif
