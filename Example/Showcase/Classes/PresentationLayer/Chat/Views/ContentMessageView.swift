import SwiftUI

struct ContentMessageView: View {

    let text: String
    let isCurrentUser: Bool

    var body: some View {
        Text(text)
            .font(.body)
            .padding(.horizontal, 16.0)
            .padding(.vertical, 10.0)
            .foregroundColor(.white)
            .background(
                // TODO: Add border
                overlayView
                    .foregroundColor(backgroundColor)
            )
    }

    private var overlayView: some View {
        return Rectangle()
            .cornerRadius(22, corners: [.topLeft, .topRight])
            .cornerRadius(22, corners: isCurrentUser ? .bottomLeft : .bottomRight)
            .cornerRadius(4, corners: isCurrentUser ? .bottomRight : .bottomLeft)
    }

    private var backgroundColor: Color {
        return isCurrentUser ? .w_secondaryBackground : .w_purpleBackground
    }

    private var borderColor: Color {
        return isCurrentUser ? .w_tertiaryBackground : .w_purpleForeground
    }
}
