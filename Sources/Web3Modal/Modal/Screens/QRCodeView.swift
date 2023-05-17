import SwiftUI
import QRCode

struct QRCodeView: View {
    
    @State var doc: QRCode.Document!
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var uri: String
    
    var body: some View {
        QRCodeViewUI(
            content: uri,
            errorCorrection: .quantize,
            foregroundColor: AssetColor.background1.uiColor.cgColor,
            backgroundColor: AssetColor.foreground1.uiColor.cgColor,
            pixelStyle: QRCode.PixelShape.Vertical(
                insetFraction: 0.2,
                cornerRadiusFraction: 1
            ),
            eyeStyle: QRCode.EyeShape.Squircle(),
            logoTemplate: QRCode.LogoTemplate(
                image: Asset.wc_logo.uiImage.cgImage!,
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
