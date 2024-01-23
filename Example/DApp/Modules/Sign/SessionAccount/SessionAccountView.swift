import SwiftUI

import WalletConnectSign

struct SessionAccountView: View {
    @EnvironmentObject var presenter: SessionAccountPresenter
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color(red: 25/255, green: 26/255, blue: 26/255)
                    .ignoresSafeArea()


                ScrollView {
                    VStack(spacing: 12) {
                        networkView(title: String(presenter.sessionAccount.chain.split(separator: ":").first ?? ""))
                        accountView(address: presenter.sessionAccount.account)
                        methodsView(methods: presenter.sessionAccount.methods)
                        
                        Spacer()
                    }
                    .padding(12)
                }

                if presenter.requesting {
                    loadingView
                        .frame(width: 200, height: 200)
                        .background(Color.gray.opacity(0.95))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }
            }
            .navigationTitle(presenter.sessionAccount.chain)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarRole(.editor)
            .toolbarBackground(
                Color(red: 25/255, green: 26/255, blue: 26/255),
                for: .navigationBar
            )
            .sheet(isPresented: $presenter.showResponse) {
                ZStack {
                    Color(red: 25/255, green: 26/255, blue: 26/255)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        responseView(response: presenter.response!)
                            .padding(12)
                    }
                }
                .presentationDetents([.medium])
            }
            .alert(presenter.errorMessage, isPresented: $presenter.showError) {
                Button("OK", role: .cancel) {}
            }
            .alert("Request sent. Check your wallet.", isPresented: $presenter.showRequestSent) {
                Button("OK", role: .cancel) {}
            }
        }
    }
    
    private func networkView(title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.02))
            
            VStack(spacing: 5) {
                Text(title)
                    .font(
                        Font.system(size: 14, weight: .medium)
                    )
                    .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(12)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.02))
                    
                    HStack(spacing: 10) {
                        Image(title == "eip155" ? "ethereum" : title.lowercased())
                            .resizable()
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(title)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 228/255, green: 231/255, blue: 231/255))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
            }
        }
    }
    
    private func accountView(address: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.02))
            
            VStack(spacing: 5) {
                Text("Address")
                    .font(
                        Font.system(size: 14, weight: .medium)
                    )
                    .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(12)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.02))
                    
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(address)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                                .padding(.vertical, 12)
                        }
                        
                        Spacer()
                        
                        Button {
                            presenter.copyUri()
                        } label: {
                            Image("copy")
                                .resizable()
                                .frame(width: 14, height: 14)
                                .padding(.trailing, 18)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
            }
        }
    }
    
    private func methodsView(methods: [String]) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.02))
            
            VStack(spacing: 5) {
                Text("Methods")
                    .font(
                        Font.system(size: 14, weight: .medium)
                    )
                    .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(12)
                
                ForEach(Array(methods.enumerated()), id: \.offset) { index, method in
                    Button {
                        presenter.onMethod(method: method)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.02))
                            
                            HStack(spacing: 10) {
                                Text(method)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                        }
                        .padding(.bottom, 12)
                        .padding(.horizontal, 8)
                    }
                    .accessibilityIdentifier("method-\(index)")
                }
            }
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                .scaleEffect(1.5)
            Text("Request sent, waiting for response")
                .foregroundColor(.white)
                .padding(.top, 20)
        }
    }

    private func responseView(response: Response) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.02))
            
            VStack(spacing: 5) {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.gray.opacity(0.5))
                        .frame(width: 30, height: 4)
                    
                }
                .padding(20)
                
                HStack {
                    Group {
                        if case RPCResult.error(_) = response.result {
                            Text("❌ Response")
                        } else {
                            Text("✅ Response")
                        }
                    }
                    .font(
                        Font.system(size: 14, weight: .medium)
                    )
                    .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                    .padding(12)
                    
                    Spacer()
                    if let lastRequest = presenter.lastRequest {
                        Text(lastRequest.method)
                            .font(
                                Font.system(size: 14, weight: .medium)
                            )
                            .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.62))
                            .padding(12)
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.02))
                    
                    switch response.result {
                    case  .response(let response):
                        Text(try! response.get(String.self).description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                        
                    case .error(let error):
                        Text(error.message)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.bottom, 12)
                .padding(.horizontal, 8)
            }
        }
    }
}

// MARK: - Previews
struct SessionAccountView_Previews: PreviewProvider {
    static var previews: some View {
        SessionAccountView()
    }
}
