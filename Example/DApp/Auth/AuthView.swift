import SwiftUI

struct AuthView: View {

    var didPressConnect: (() -> Void)?

    @State var qrCode: UIImage?

    var body: some View {
        VStack {
            Button {
//                didPressConnect?()
                qrCode = generateQRCode()
            } label: {
                Text("Auth")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
            }
            .background(Color.blue)
            .cornerRadius(8)

            if let qrCode = qrCode {
                Image(uiImage: qrCode)
            } else {
                EmptyView()
            }
            Spacer()
        }
    }

    func generateQRCode() -> UIImage? {
        let string = "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2?relay-protocol=iridium&symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303"
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 4, y: 4)
            if let output = filter.outputImage?.transformed(by: transform) {
                if let qrCodeCGImage = CIContext().createCGImage(output, from: output.extent) {
                    print("QR code gen")
                    return UIImage(cgImage: qrCodeCGImage)
                }
            }
        }
        return nil
    }

    private func generateQRCode2() -> UIImage? {
        let string = "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2?relay-protocol=iridium&symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303"
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 4, y: 4)
            if let output = filter.outputImage?.transformed(by: transform) {
                print("QR code gen")
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
}

//import CoreImage.CIFilterBuiltins

struct AuthView_Previews: PreviewProvider {

    static func generateQRCode() -> UIImage? {
        let string = "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2?relay-protocol=iridium&symKey=587d5484ce2a2a6ee3ba1962fdd7e8588e06200c46823bd18fbd67def96ad303"
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 4, y: 4)
            if let output = filter.outputImage?.transformed(by: transform) {
                if let qrCodeCGImage = CIContext().createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: qrCodeCGImage)
                }
            }
        }
        return nil
    }

    static var previews: some View {
        AuthView(didPressConnect: nil, qrCode: generateQRCode())
        AuthView(didPressConnect: nil, qrCode: nil)
    }
}
