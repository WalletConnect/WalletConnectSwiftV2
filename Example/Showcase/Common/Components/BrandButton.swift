import SwiftUI
import AsyncButton

struct BrandButton: View {
    let title: String
    let action: () async throws -> Void

    var body: some View {
        AsyncButton(options: [.automatic]) {
            try await action()
        } label: {
            Text(title)
                .foregroundColor(.w_foreground)
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Capsule()
                        .foregroundColor(.w_greenForground)
                )
        }
    }
}


