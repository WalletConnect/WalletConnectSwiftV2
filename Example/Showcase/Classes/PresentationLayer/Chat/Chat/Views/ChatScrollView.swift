import SwiftUI

struct ChatScrollView<Content>: View where Content: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Spacer()
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )

                content()
            }
            .rotationEffect(Angle(degrees: 180))
        }
        .rotationEffect(Angle(degrees: 180))
    }
}
