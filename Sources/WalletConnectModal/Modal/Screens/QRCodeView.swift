import QRCode
import SwiftUI

struct QRCodeView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var uri: String
    
    @State var index: Int = 0
    
    var foreground1: UIColor {
        UIColor(.foreground1).resolvedColor(
            with: UITraitCollection(
                userInterfaceStyle: colorScheme == .dark ? .dark : .light
            )
        )
    }
    
    var background1: UIColor {
        UIColor(.background1).resolvedColor(
            with: UITraitCollection(
                userInterfaceStyle: colorScheme == .dark ? .dark : .light
            )
        )
    }
    
    var body: some View {
        render(
            content: uri,
            size: .init(
                width: UIScreen.main.bounds.width - 40,
                height: UIScreen.main.bounds.width - 40
            )
        )
        .colorScheme(.dark)
    }
            
    private func render(content: String, size: CGSize) -> Image {
        let doc = QRCode.Document(
            utf8String: content,
            errorCorrection: .quantize
        )
        doc.design.shape.eye = QRCode.EyeShape.Squircle()
        doc.design.shape.onPixels = QRCode.PixelShape.Vertical(
            insetFraction: 0.2,
            cornerRadiusFraction: 1
        )
        
        doc.design.style.eye = QRCode.FillStyle.Solid(foreground1.cgColor)
        doc.design.style.pupil = QRCode.FillStyle.Solid(foreground1.cgColor)
        doc.design.style.onPixels = QRCode.FillStyle.Solid(foreground1.cgColor)
        doc.design.style.background = QRCode.FillStyle.Solid(background1.cgColor)
        
        doc.logoTemplate = QRCode.LogoTemplate(
            image: Asset.wc_logo.uiImage.cgImage!,
            path: CGPath(
                rect: CGRect(x: 0.35, y: 0.3875, width: 0.30, height: 0.225),
                transform: nil
            )
        )
        
        return doc.imageUI(
            size, label: Text("QR code with URI")
        )!
    }
}
            
extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: size))
        }
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static let stubUri: String = Array(repeating: ["a", "b", "c", "1", "2", "3"], count: 10)
        .flatMap { $0 }
        .shuffled()
        .joined()
    
    static var previews: some View {
        QRCodeView(uri: stubUri)
            .previewLayout(.sizeThatFits)
    }
}
