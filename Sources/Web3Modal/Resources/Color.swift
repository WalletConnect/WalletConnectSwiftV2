import SwiftUI

enum AssetColor: String {
    case foreground1
    case foreground2
    case foreground3
    case foregroundInverse
    case background1
    case background2
    case background3
    case negative
    case thickOverlay
    case thinOverlay
    case accent
}

extension Color {
 
    init(_ asset: AssetColor) {
        self.init(asset.rawValue, bundle: .module)
    }
    
    static let foreground1 = Color(.foreground1)
    static let foreground2 = Color(.foreground2)
    static let foreground3 = Color(.foreground3)
    static let foregroundInverse = Color(.foregroundInverse)
    static let background1 = Color(.background1)
    static let background2 = Color(.background2)
    static let background3 = Color(.background3)
    static let negative = Color(.negative)
    static let thickOverlay = Color(.thickOverlay)
    static let thinOverlay = Color(.thinOverlay)
    static let accent = Color(.accent)
}

extension UIColor {
 
    convenience init(_ asset: AssetColor) {
        self.init(named: asset.rawValue, in: .module, compatibleWith: nil)!
    }
}

extension AssetColor {
    
    var swituiColor: Color {
        Color(self)
    }
    
    var uiColor: UIColor {
        UIColor(self)
    }
}

@available(iOS 15.0, *)
struct Color_Previews: PreviewProvider {
    static var allColors: [AssetColor] {
        [
            .foreground1,
            .foreground2,
            .foreground3,
            .foregroundInverse,
            .background1,
            .background2,
            .background3,
            .negative,
            .thickOverlay,
            .thinOverlay,
            .accent,
        ]
    }

    static var previews: some View {
        VStack {
            let columns = [
                GridItem(.adaptive(minimum: 150)),
            ]

            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(allColors, id: \.self) { colorAsset in

                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorAsset.swituiColor)
                            .frame(width: 62, height: 62)

                        Text(colorAsset.rawValue).bold()
                    }
                    .font(.footnote)
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
