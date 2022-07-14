import SwiftUI

struct ChatListView: View {

    @EnvironmentObject var presenter: ChatListPresenter

    var body: some View {
        ScrollView {
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

                Spacer()

                Button("Log out") {
                    presenter.didLogoutPress()
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            presenter.setupInitialState()
        }
    }
}

#if DEBUG
struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
}
#endif
