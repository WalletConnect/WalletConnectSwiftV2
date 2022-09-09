import SwiftUI

struct ScanView: View {

    @EnvironmentObject var presenter: ScanPresenter

    var body: some View {
        ScanQR(onValue: presenter.onValue, onError: presenter.onError)
            .ignoresSafeArea()
    }
}

#if DEBUG
struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        ScanView()
    }
}
#endif
