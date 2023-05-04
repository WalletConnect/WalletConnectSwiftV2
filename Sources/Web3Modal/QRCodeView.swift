import SwiftUI
import QRCode

struct QRCodeView: View {
    
    @State var doc: QRCode.Document!
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    
    
    var body: some View {
        
        GeometryReader { g in
            VStack(alignment: .center) {
                render(frame: g.frame(in: .local))
            }
        }
        .padding(.bottom, 40)
    }
    
    func render(frame: CGRect) -> Image? {
        let doc = QRCode.Document(
            utf8String: Array(repeating: ["a", "b", "c", "1", "2", "3"], count: 50).flatMap({ $0 }).shuffled().joined(),
            errorCorrection: .high
        )

        doc.design.shape.eye = QRCode.EyeShape.Squircle()
        doc.design.shape.onPixels = QRCode.PixelShape.Vertical(
            insetFraction: 0.2,
            cornerRadiusFraction: 1
        )
        
        doc.design.style.eye = QRCode.FillStyle.Solid(colorScheme == .light ? UIColor.black.cgColor : UIColor.white.cgColor)
        doc.design.style.pupil = QRCode.FillStyle.Solid(colorScheme == .light ? UIColor.black.cgColor : UIColor.white.cgColor)
        doc.design.style.onPixels = QRCode.FillStyle.Solid(colorScheme == .light ? UIColor.black.cgColor : UIColor.white.cgColor)
        doc.design.style.background = QRCode.FillStyle.Solid(colorScheme == .light ? UIColor.white.cgColor : UIColor.black.cgColor)
        
        guard let logo = UIImage(named: "wc_logo", in: .module, with: .none)?.cgImage else {
            return doc.imageUI(
                frame.size, label: Text("fooo")
            )
        }

        doc.logoTemplate = QRCode.LogoTemplate(
            image: logo,
            path: CGPath(
                rect: CGRect(x: 0.35, y: 0.3875, width: 0.30, height: 0.225),
                transform: nil
            )
        )
        
        return doc.imageUI(
            frame.size, label: Text("fooo")
        )
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
