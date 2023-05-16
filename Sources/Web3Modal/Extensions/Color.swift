import SwiftUI

extension Color {
    static let foreground1 = Color("foreground1", bundle: .module)
    static let foreground2 = Color("foreground2", bundle: .module)
    static let foreground3 = Color("foreground3", bundle: .module)
    static let foregroundInverse = Color("foregroundInverse", bundle: .module)
    static let background1 = Color("background1", bundle: .module)
    static let background2 = Color("background2", bundle: .module)
    static let background3 = Color("background3", bundle: .module)
    static let negative = Color("negative", bundle: .module)
    static let thickOverlay = Color("thickOverlay", bundle: .module)
    static let thinOverlay = Color("thinOverlay", bundle: .module)
    static let accent = Color("accent", bundle: .module)
}

@available(iOS 15.0, *)
struct Color_Previews: PreviewProvider {
    static var allColors: [(String, Color)] {
        [
            ("foreground1", Color("foreground1", bundle: .module)),
            ("foreground2", Color("foreground2", bundle: .module)),
            ("foreground3", Color("foreground3", bundle: .module)),
            ("foregroundInverse", Color("foregroundInverse", bundle: .module)),
            ("background1", Color("background1", bundle: .module)),
            ("background2", Color("background2", bundle: .module)),
            ("background3", Color("background3", bundle: .module)),
            ("negative", Color("negative", bundle: .module)),
            ("thickOverlay", Color("thickOverlay", bundle: .module)),
            ("thinOverlay", Color("thinOverlay", bundle: .module)),
            ("accent", Color("accent", bundle: .module)),
        ]
    }

    static var previews: some View {
        VStack {
            let columns = [
                GridItem(.adaptive(minimum: 150)),
            ]

            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(allColors, id: \.1) { name, color in

                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color)
                            .frame(width: 62, height: 62)

                        Text(name).bold()
                    }
                    .font(.footnote)
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
