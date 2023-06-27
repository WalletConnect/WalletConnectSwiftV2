import QRCode
import SwiftUI

struct QRCodeView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var uri: String
    
    @State var index: Int = 0
    
    var body: some View {
        
        #if canImport(UIKit)
        
        let size: CGSize = .init(
            width: UIScreen.main.bounds.width - 40,
            height: UIScreen.main.bounds.height * 0.4
        )
        
        #elseif canImport(AppKit)
        
        let size: CGSize = .init(
            width: 300,
            height: NSScreen.main!.frame.height * 0.4
        )
        
        #endif
        
        render(
            content: uri,
            size: size
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
            image: Asset.wc_logo.cgImage,
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

#if canImport(UIKit)

typealias Screen = UIScreen

extension QRCodeView {
    var foreground1: UIColor {
        UIColor(AssetColor.foreground1).resolvedColor(
            with: UITraitCollection(
                userInterfaceStyle: colorScheme == .dark ? .dark : .light
            )
        )
    }
    
    var background1: UIColor {
        UIColor(AssetColor.background1).resolvedColor(
            with: UITraitCollection(
                userInterfaceStyle: colorScheme == .dark ? .dark : .light
            )
        )
    }
}

#elseif canImport(AppKit)

typealias Screen = NSScreen

extension QRCodeView {
    var foreground1: NSColor {
        NSColor(AssetColor.foreground1)
//            .resolvedColor(
//            with: NSTraitCollection(
//                userInterfaceStyle: colorScheme == .dark ? .dark : .light
//            )
//        )
    }
    
    var background1: NSColor {
        NSColor(AssetColor.background1)
//            .resolvedColor(
//            with: NSTraitCollection(
//                userInterfaceStyle: colorScheme == .dark ? .dark : .light
//            )
//        )
    }
}

#endif

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
