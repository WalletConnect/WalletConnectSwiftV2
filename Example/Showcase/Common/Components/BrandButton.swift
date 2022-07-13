import SwiftUI

struct BrandButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Binding<Bool>

    var body: some View {
        Button(action: { action() }, label: {
            Text(title)
                .foregroundColor(.w_foreground)
                .font(.system(size: 20, weight: .bold))
        })
//        .disabled(!isEnabled.wrappedValue)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            Capsule()
                .foregroundColor(.w_greenForground)
        )
    }
}
