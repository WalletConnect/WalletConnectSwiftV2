import SwiftUI

extension Color {
    
    static var secondaryLabel: Color {
        if #available(iOS 15.0, *) {
            return Color(uiColor: .secondaryLabel)
        } else {
            return Color.white
        }
    }
    
    static var tertiaryLabel: Color {
        if #available(iOS 15.0, *) {
            return Color(uiColor: .tertiaryLabel)
        } else {
            return Color.white
        }
    }
    
    static var secondarySystemBackground: Color {
        if #available(iOS 15.0, *) {
            return Color(uiColor: .secondarySystemBackground)
        } else {
            return Color.white
        }
    }
}
