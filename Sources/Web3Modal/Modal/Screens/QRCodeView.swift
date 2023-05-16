import SwiftUI
import QRCode

struct QRCodeView: View {
    
    @State var doc: QRCode.Document!
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var uri: String
    
    var body: some View {
        
        let backgroundColor = UIColor(named: "background1", in: .module, compatibleWith: nil)!.cgColor
        let foregroundColor = UIColor(named: "foreground1", in: .module, compatibleWith: .current)!.cgColor

        QRCodeViewUI(
            content: uri,
            errorCorrection: .quantize,
            foregroundColor: foregroundColor,
            backgroundColor: backgroundColor,
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
        .frame(height: UIScreen.main.bounds.width)
    }
}

struct QRCodeView_Previews: PreviewProvider {
    
    static let stubUri: String = Array(repeating: ["a", "b", "c", "1", "2", "3"], count: 50)
        .flatMap({ $0 })
        .shuffled()
        .joined()
    
    static var previews: some View {
        QRCodeView(uri: stubUri)
            .previewLayout(.sizeThatFits)
    }
}
