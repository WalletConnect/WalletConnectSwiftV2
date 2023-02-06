import SwiftUI

struct PushMessagesView: View {

    @EnvironmentObject var presenter: PushMessagesPresenter

    var body: some View {
        Text("PushMessages module")
    }
}

#if DEBUG
struct PushMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        PushMessagesView()
    }
}
#endif
