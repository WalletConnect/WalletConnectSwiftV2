
import SwiftUI

struct CircuralIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 28, height: 28)
            .background(Color.background1)
            .foregroundColor(.foreground1)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.8 : 1)
            .animation(.default, value: configuration.isPressed)
    }
}

struct W3MButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.accent)
            .foregroundColor(.foregroundInverse)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.default, value: configuration.isPressed)
    }
}

struct ButtonStyle_Previews: PreviewProvider {
    
    static var previews: some View {
        
        VStack {
            
            Button("Foo", action: {})
                .buttonStyle(W3MButtonStyle())
            
            Button("F", action: {})
                .buttonStyle(CircuralIconButtonStyle())
        }
        .background(Color.background3)
        .previewLayout(.sizeThatFits)
    }
}
