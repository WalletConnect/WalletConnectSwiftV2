import SwiftUI
import AsyncButton

struct PlainButton<Label> : View where Label : View {

    let action: () async throws -> Void
    let label: () -> Label

    var body: some View {
        AsyncButton(options: [.automatic]) {
            try await action()
        } label: {
            label()
        }
    }
}
