import SwiftUI

public struct Web3ModalSheet: View {
    
    @State public var destination: Destination
    @Binding public var isShown: Bool
    
    public enum Destination: String {
        case welcome
        case help
        case qr
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color.white
            
            VStack {
                Color.blue
                    .frame(height: 40)
                    .overlay(
                        HStack() {
                            backButton()
                                .disabled(destination == .welcome)
                            
                            Spacer()
                            
                            closeButton()
                        },
                        alignment: .topTrailing
                    )
                
                switch destination {
                case .welcome:
                    
                    Button("Help") {
                        withAnimation {
                            destination = .help
                        }
                    }
                    
                    Button("QR") {
                        withAnimation {
                            destination = .qr
                        }
                    }
                case .help:
                    WhatIsWalletView()
                case .qr:
                    QRCodeView()
                }
            }
        }
    }
    
    func backButton() -> some View {
        Button(action: {
            withAnimation {
                destination = .welcome
            }
        }, label: {
            Image(systemName: "chevron.backward")
                .foregroundColor(.black)
        })
        .padding()
    }
    
    func closeButton() -> some View {
        Button(action: {
            withAnimation {
                isShown = false
            }
        }, label: {
            Image(systemName: "x.circle")
                .foregroundColor(.black)
        })
        .padding()
    }
}

struct Web3ModalSheet_Previews: PreviewProvider {
    static var previews: some View {
        Web3ModalSheet(destination: .welcome, isShown: .constant(true))
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
        
        Web3ModalSheet(destination: .qr, isShown: .constant(true))
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}
