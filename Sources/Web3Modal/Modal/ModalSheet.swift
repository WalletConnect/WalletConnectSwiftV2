import SwiftUI

public struct ModalSheet: View {
    @ObservedObject var viewModel: ModalViewModel
    
    public var body: some View {
        VStack(spacing: 0) {
            modalHeader()
            
            VStack(spacing: 0) {
                contentHeader()
                content()
            }
            .frame(maxWidth: .infinity)
            .background(Color.background1)
            .cornerRadius(30, corners: [.topLeft, .topRight])
        }
        .padding(.bottom, 40)
        .onAppear {
            Task {
                await viewModel.createURI()
//                await viewModel.fetchWallets()
            }
        }
        .background(
            VStack(spacing: 0) {
                Color.accent
                    .frame(height: 90)
                    .cornerRadius(8, corners: [[.topLeft, .topRight]])
                Color.background1
            }
        )
    }
    
    private func modalHeader() -> some View {
        HStack(spacing: 0) {
            Image(.walletconnect_logo)
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .padding(.leading, 10)
            
            Spacer()
            
            HStack(spacing: 16) {
                helpButton()
                closeButton()
            }
            .padding(.trailing, 10)
        }
        .foregroundColor(Color.foreground1)
        .frame(height: 48)
    }
    
    private func contentHeader() -> some View {
        HStack(spacing: 0) {
            if viewModel.destination != .wallets {
                backButton()
            }
            
            Spacer()
            
            switch viewModel.destination {
            case .wallets:
                qrButton()
            case .qr:
                copyButton()
            default:
                EmptyView()
            }
        }
        .animation(.default)
        .foregroundColor(.accent)
        .frame(height: 60)
        .overlay(
            Text(viewModel.destination.contentTitle)
                .font(.system(size: 20).weight(.semibold))
                .foregroundColor(.foreground1)
                .padding(.horizontal, 50)
        )
    }
    
    @ViewBuilder
    private func content() -> some View {
        switch viewModel.destination {
        case .wallets:
            
            Text("TBD in subsequent PR")
            
//            ZStack {
//                VStack {
//                    HStack {
//                        ForEach(0..<4) { wallet in
//                            gridItem(for: wallet)
//                        }
//                    }
//                    HStack {
//                        ForEach(4..<7) { wallet in
//                            gridItem(for: wallet)
//                        }
//                    }
//                }
//
//                Spacer().frame(height: 200)
//            }
            
        case .help:
            WhatIsWalletView()
        case .qr:
            VStack {
                if let uri = viewModel.uri {
                    QRCodeView(uri: uri)
                } else {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                }
            }
        }
    }
    
//    @ViewBuilder
//    private func gridItem(for index: Int) -> some View {
//        let wallet: Listing = viewModel.wallets.indices.contains(index) ? viewModel.wallets[index] : nil
//
//        if #available(iOS 14.0, *) {
//            VStack {
//                AsyncImage(url: wallet != nil ? viewModel.imageUrl(for: wallet!) : nil) { image in
//                    image
//                        .resizable()
//                        .scaledToFit()
//                } placeholder: {
//                    Color.foreground3
//                }
//                .cornerRadius(8)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 8)
//                        .stroke(.gray.opacity(0.4), lineWidth: 1)
//                )
//
//                Text(wallet?.name ?? "WalletName")
//                    .font(.system(size: 12))
//                    .foregroundColor(.foreground1)
//                    .padding(.horizontal, 12)
//                    .fixedSize(horizontal: true, vertical: true)
//
//                Text("RECENT")
//                    .opacity(0)
//                    .font(.system(size: 10))
//                    .foregroundColor(.foreground3)
//                    .padding(.horizontal, 12)
//            }
//            .redacted(reason: wallet == nil ? .placeholder : [])
//            .frame(maxWidth: 80, maxHeight: 96)
//        }
//    }
    
    private func helpButton() -> some View {
        Button(action: {
            withAnimation {
                viewModel.navigateTo(.help)
            }
        }, label: {
            Image(.help)
                .padding(8)
        })
        .buttonStyle(CircuralIconButtonStyle())
    }
    
    private func closeButton() -> some View {
        Button {
            withAnimation {
                viewModel.isShown.wrappedValue = false
            }
        } label: {
            Image(.close)
                .padding(8)
        }
        .buttonStyle(CircuralIconButtonStyle())
    }
    
    private func backButton() -> some View {
        Button {
            withAnimation {
                viewModel.onBackButton()
            }
        } label: {
            Image(systemName: "chevron.backward")
                .padding(20)
        }
    }
    
    private func qrButton() -> some View {
        Button {
            withAnimation {
                viewModel.navigateTo(.qr)
            }
        } label: {
            Image(.qr_large)
                .padding()
        }
    }
    
    private func copyButton() -> some View {
        Button {
            viewModel.onCopyButton()
        } label: {
            Image(.copy_large)
                .padding()
        }
    }
}
