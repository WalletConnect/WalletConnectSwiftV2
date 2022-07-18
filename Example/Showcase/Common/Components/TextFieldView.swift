import SwiftUI

struct TextFieldView: View {

    let title: String
    let placeholder: String
    let input: Binding<String>

    private var isClearVisible: Bool {
        return input.wrappedValue.count > 0
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.w_secondaryForeground)
                .padding(.horizontal, 16.0)

            HStack {
                TextField(placeholder, text: input)
                    .font(.body)
                    .foregroundColor(.w_foreground)
                    .disableAutocorrection(true)

                if isClearVisible {
                    Button(action: { didPressClear() }) {
                        Image(systemName: "xmark.circle.fill")
                            .frame(width: 17.0, height: 17.0)
                    }
                }
            }
            .padding(.horizontal, 16.0)
        }
        .frame(height: 72.0)
        .background(
            RoundedRectangle(cornerRadius: 14.0)
                .foregroundColor(.w_secondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14.0)
                .stroke(Color.w_tertiaryBackground, lineWidth: 0.5)
        )
        .padding(16.0)
    }

    private func didPressClear() {
        input.wrappedValue = .empty
    }
}
