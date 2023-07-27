
import SwiftUI

struct CircuralIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(width: 28, height: 28)
            .background(Color.background1)
            .foregroundColor(.foreground1)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.default, value: configuration.isPressed)
    }
}

struct WCMAccentButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.background2)
            .foregroundColor(.accent)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.thinOverlay, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.default, value: configuration.isPressed)
    }
}

struct WCMMainButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.accent)
            .foregroundColor(.foregroundInverse)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.default, value: configuration.isPressed)
    }
}

#if DEBUG
struct ButtonStyle_Previews: PreviewProvider {
    
    static var previews: some View {
        
        VStack {
            Button("Accent", action: {})
                .buttonStyle(WCMAccentButtonStyle())
            
            Button("Main", action: {})
                .buttonStyle(WCMMainButtonStyle())
            
            Button("F", action: {})
                .buttonStyle(CircuralIconButtonStyle())
        }
        .background(Color.background3)
        .previewLayout(.sizeThatFits)
    }
}
#endif
