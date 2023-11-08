import QRCode
import SwiftUI

struct QRCodeView: View {
    
    @State var uri: String
    
    var body: some View {
        
        #if canImport(UIKit)
        
        let size: CGSize = .init(
            width: UIScreen.main.bounds.width - 20,
            height: UIScreen.main.bounds.height * 0.4
        )
        
        #elseif canImport(AppKit)
        
        let size: CGSize = .init(
            width: NSScreen.main!.frame.width,
            height: NSScreen.main!.frame.height * 0.3
        )
        
        #endif
        
        let height: CGFloat = min(size.width, size.height)
        
        VStack(alignment: .center) {
            render(
                content: uri,
                size: .init(width: height, height: height)
            )
            .colorScheme(.light)
            .frame(width: height, height: height)
        }
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
            image: Asset.wc_logo.cgImage,
            path: CGPath(
                rect: CGRect(x: 0.35, y: 0.3875, width: 0.30, height: 0.225),
                transform: nil
            )
        )
        
        if #available(macOS 11, *) {
            return doc.imageUI(
                size, label: Text("QR code with URI")
            )!
        } else {
            return Image.init(sfSymbolName: "qrcode")
        }
    }
}

#if canImport(UIKit)

typealias Screen = UIScreen

extension QRCodeView {
    var foreground1: UIColor {
        UIColor(AssetColor.foreground1)
    }
    
    var background1: UIColor {
        UIColor(AssetColor.background1)
    }
}

#elseif canImport(AppKit)

typealias Screen = NSScreen

extension QRCodeView {
    var foreground1: NSColor {
        NSColor(AssetColor.foreground1)
    }
    
    var background1: NSColor {
        NSColor(AssetColor.background1)
    }
}

#endif

#if DEBUG
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
#endif
