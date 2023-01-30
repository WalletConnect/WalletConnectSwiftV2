import SwiftUI

struct ChatListView: View {

    @EnvironmentObject var presenter: ChatListPresenter

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        if presenter.showRequests {
                            Button(action: {
                                presenter.didPressChatRequests()
                            }) {
                                HStack(spacing: 8.0) {
                                    Text(presenter.requestsCount)
                                        .frame(width: 24.0, height: 24.0)
                                        .background(Color.w_greenForground)
                                        .foregroundColor(.w_greenBackground)
                                        .font(.system(size: 17.0, weight: .bold))
                                        .clipShape(Circle())

                                    Text("Chat Requests")
                                        .foregroundColor(.w_greenForground)
                                        .font(.system(size: 17.0, weight: .bold))
                                }
                            }
                            .frame(height: 44.0)
                            .frame(maxWidth: .infinity)
                            .background(Color.w_greenBackground)
                            .clipShape(Capsule())
                            .padding(16.0)
                        }

                        if presenter.threads.isEmpty {
                            Spacer()
                            emptyView(size: geometry.size)
                            Spacer()
                        } else {
                            chatsList()
                        }
                    }
                }

                Button("Log out") {
                    presenter.didLogoutPress()
                }
                .foregroundColor(.red)
                .padding(.bottom, 16)
            }
            .onAppear {
                presenter.setupInitialState()
            }
        }
    }

    private func chatsList() -> some View {
        ForEach(presenter.threads) { thread in
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
