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
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            Task {
                await viewModel.fetchWallets()
                await viewModel.createURI()
            }
        }
        .background(
            ZStack {
                Color.thickOverlay.colorScheme(.light)
                
                VStack(spacing: 0) {
                    Color.accent
                        .frame(height: 90)
                        .cornerRadius(8, corners: [[.topLeft, .topRight]])
                    Color.background1
                }
            }
        )
        .toastView(toast: $viewModel.toast)
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
            if viewModel.destinationStack.count > 1 {
                backButton()
            }
            
            Spacer()
            
            switch viewModel.destination {
            case .welcome:
                qrButton()
            case .qr, .walletDetail:
                copyButton()
            default:
                EmptyView()
            }
        }
        .animation(.default)
        .foregroundColor(.accent)
        .frame(height: 60)
        .overlay(
            VStack {
                if viewModel.destination.hasSearch {
                    TextField("Search", text: $viewModel.searchTerm)
                        .transform {
                            #if os(iOS)
                            $0.textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                            #endif
                        }
                        .padding(.horizontal, 50)
                } else {
                    Text(viewModel.destination.contentTitle)
                        .font(.system(size: 20).weight(.semibold))
                        .foregroundColor(.foreground1)
                        .padding(.horizontal, 50)
                }
            }
        )
    }
    
    @ViewBuilder
    private func welcome() -> some View {
        WalletList(
            wallets: .init(get: {
                viewModel.filteredWallets
            }, set: { _ in }),
            destination: .init(get: {
                viewModel.destination
            }, set: { _ in }),
            navigateTo: viewModel.navigateTo(_:),
            onListingTap: viewModel.onListingTap(_:)
        )
    }
    
    private func qrCode() -> some View {
        VStack {
            if let uri = viewModel.uri {
                QRCodeView(uri: uri)
            } else {
                ActivityIndicator(isAnimating: .constant(true))
            }
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        switch viewModel.destination {
        case .welcome,
             .walletDetail,
             .viewAll:
            welcome()
        case .help:
            WhatIsWalletView(
                navigateTo: viewModel.navigateTo(_:),
                navigateToExternalLink: viewModel.navigateToExternalLink(_:)
            )
        case .qr:
            qrCode()
        case .getWallet:
            GetAWalletView(
                wallets: Array(viewModel.wallets.prefix(6)),
                onWalletTap: viewModel.onGetWalletTap(_:),
                navigateToExternalLink: viewModel.navigateToExternalLink(_:)
            )
        }
    }
}

extension ModalSheet {
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
            viewModel.onCloseButton()
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
