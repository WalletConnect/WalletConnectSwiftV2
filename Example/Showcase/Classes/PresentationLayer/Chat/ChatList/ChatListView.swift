import SwiftUI

struct ChatListView: View {

    @EnvironmentObject var presenter: ChatListPresenter

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        HStack {
                            if presenter.showReceivedInvites {
                                invitesButton(title: "Received Invites", count: presenter.receivedInviteViewModels.count, textColor: .w_greenForground, backgroundColor: .w_greenBackground) {
                                    presenter.didPressReceivedInvites()
                                }
                            }

                            if presenter.showSentInvites {
                                invitesButton(title: "Sent Invites", count: presenter.sentInviteViewModels.count, textColor: .w_foreground, backgroundColor: .w_purpleBackground) {
                                    presenter.didPressSentInvites()
                                }
                            }

                            Spacer()
                        }
                        .padding(16.0)
                        
                        if presenter.threadViewModels.isEmpty {
                            Spacer()
                            emptyView(size: geometry.size)
                            Spacer()
                        } else {
                            chatsList()
                        }
                    }
                }

                PlainButton {
                    try await presenter.didCopyPress()
                } label: {
                    Text("Copy account")
                        .foregroundColor(.white)
                }
                .padding(.bottom, 16)

                PlainButton {
                    try await presenter.didLogoutPress()
                } label: {
                    Text("Log out")
                        .foregroundColor(.red)
                }
                .padding(.bottom, 16)
            }
        }
    }

    private func invitesButton(
        title: String,
        count: Int,
        textColor: Color,
        backgroundColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8.0) {
                Text(String(count))
                    .frame(width: 24.0, height: 24.0)
                    .background(textColor)
                    .foregroundColor(backgroundColor)
                    .font(.system(size: 15.0, weight: .bold))
                    .clipShape(Circle())

                Text(title)
                    .foregroundColor(textColor)
                    .font(.system(size: 15.0, weight: .bold))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .frame(height: 44.0)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    private func chatsList() -> some View {
        ForEach(presenter.threadViewModels) { thread in
            Button(action: {
                presenter.didPressThread(thread)
            }) {
                HStack(spacing: 16.0) {
                    Image("avatar")
                        .resizable()
                        .frame(width: 64.0, height: 64.0)

                    VStack(alignment: .leading) {
                        Text(thread.title)
                            .font(.title3)
                            .foregroundColor(.w_foreground)
                            .lineLimit(1)

                        Text(thread.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.w_secondaryForeground)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(height: 64.0)
            }
        }
        .padding(16.0)
    }

    private func emptyView(size: CGSize) -> some View {
        VStack(spacing: 8.0) {
            Text("It’s empty in here")
                .font(.system(.title3))
                .foregroundColor(.w_foreground)

            Text("Start a conversation with your web3 frens")
                .font(.body)
                .foregroundColor(.w_secondaryForeground)
                .padding(.bottom, 8.0)

            Button(action: { presenter.didPressNewChat() }, label: {
                HStack(spacing: 8.0) {
                    Image("plus_icon")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("New chat")
                        .foregroundColor(.w_foreground)
                        .font(.system(size: 18, weight: .semibold))
                }
                .padding(.trailing, 8.0)
            })
            .frame(width: 128, height: 44)
            .background(
                Capsule()
                    .foregroundColor(.w_greenForground)
            )
        }
        .frame(width: size.width)
        .frame(minHeight: size.height)
    }
}

#if DEBUG
struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
#endif
