import SwiftUI

struct AuthRequestView: View {

    @EnvironmentObject var presenter: AuthRequestPresenter

    var body: some View {
        Text(presenter.message)
    }
}

#if DEBUG
struct AuthRequestView_Previews: PreviewProvider {
    static var previews: some View {
        AuthRequestView()
    }
}
#endif
