import SwiftUI
import QRCode

struct QRCodeView: View {
    
    @State var doc: QRCode.Document!
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
        
    var body: some View {
        
        QRCodeViewUI(
            content: Array(repeating: ["a", "b", "c", "1", "2", "3"], count: 50).flatMap({ $0 }).shuffled().joined(),
            foregroundColor: colorScheme == .light ? UIColor.black.cgColor : UIColor.white.cgColor,
            backgroundColor: colorScheme == .light ? UIColor.white.cgColor : UIColor.black.cgColor,
            pixelStyle: QRCode.PixelShape.Vertical(
                insetFraction: 0.2,
                cornerRadiusFraction: 1
            ),
            eyeStyle: QRCode.EyeShape.Squircle(),
            logoTemplate: QRCode.LogoTemplate(
                image: (UIImage(named: "wc_logo", in: .module, with: .none)?.cgImage)!,
                path: CGPath(
                    rect: CGRect(x: 0.35, y: 0.3875, width: 0.30, height: 0.225),
                    transform: nil
                )
            )
        )
        .padding(.bottom, 40)
    }
}


struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        
        QRCodeView()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
    }
}
