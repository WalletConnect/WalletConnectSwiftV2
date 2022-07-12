import SwiftUI

struct ImportView: View {

    @EnvironmentObject var presenter: ImportPresenter

    var body: some View {
        Text("Import module")
    }
}

#if DEBUG
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView()
    }
}
#endif
