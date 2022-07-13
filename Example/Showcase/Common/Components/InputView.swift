import SwiftUI

struct InputView: View {

    let title: String
    let text: Binding<String>
    let action: () -> Void

    var body: some View {
        ZStack {
            TextField(title, text: text)
                .disableAutocorrection(true)
                .frame(minHeight: 44.0)
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .background(
                    Capsule()
                        .foregroundColor(.w_secondaryBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.w_tertiaryBackground, lineWidth: 0.5)
                )
                .onSubmit {
                    action()
                }
        }
    }
}
