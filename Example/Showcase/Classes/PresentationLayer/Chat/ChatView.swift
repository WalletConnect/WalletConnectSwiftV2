import SwiftUI

struct ChatView: View {

    @EnvironmentObject var viewModel: ChatPresenter

    var body: some View {
        Text("Chat module")
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
#endif
