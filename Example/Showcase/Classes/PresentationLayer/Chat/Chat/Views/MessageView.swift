import SwiftUI

struct MessageView: View {

    let message: MessageViewModel

    var body: some View {
        HStack(spacing: 8.0) {
            if message.isCurrentUser {
                Spacer()
            }

            if message.showAvatar {
                Image("avatar")
                    .resizable()
                    .frame(width: 44, height: 44, alignment: .center)
                    .cornerRadius(22)
            }

            ContentMessageView(text: message.text, isCurrentUser: message.isCurrentUser)

            if !message.isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 16.0)
    }
}
