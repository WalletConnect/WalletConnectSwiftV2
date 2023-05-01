import SwiftUI

public struct Web3ModalSheet: View {
    
    @State var destination: Destination = .welcome
    
    enum Destination: String {
        case welcome
        case help
        case qr
        
        var preferredHeight: CGFloat {
            switch self {
            case .welcome:
                return 300
            case .help:
                return 600
            case .qr:
                return 400
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color.white
            
            VStack {
                Color.cyan
                    .frame(height: 40)
                
                switch destination {
                case .welcome:
                    
                    Button("Help") {
                        withAnimation(.default) {
                            destination = .help
                        }
                    }
                    
                    Button("QR") {
                        withAnimation(.default) {
                            destination = .qr
                        }
                    }
                case .help:
                    WhatIsWalletView()
                        .overlay(
                            backButton(),
                            alignment: .topTrailing
                        )
                case .qr:
                    QRCodeView()
                        .overlay(
                            backButton(),
                            alignment: .topTrailing
                        )
                }
            }
        }
        .frame(height: destination.preferredHeight)
    }
    
    func backButton() -> some View {
        Button(action: {
            withAnimation(.default) {
                destination = .welcome
            }
        }, label: {
            Image(systemName: "x.circle")
                .foregroundColor(.black)
        })
    }
}

struct Web3ModalSheet_Previews: PreviewProvider {
    static var previews: some View {
        Web3ModalSheet()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
        
        Web3ModalSheet()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}
