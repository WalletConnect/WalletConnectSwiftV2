import SwiftUI

struct ChatListView: View {

    @EnvironmentObject var presenter: ChatListPresenter

    var body: some View {
        VStack {
            Spacer()

            Button("Chat Requests") {
                presenter.didPressChatRequests()
            }
        }
        .task {
            await presenter.setupInitialState()
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
