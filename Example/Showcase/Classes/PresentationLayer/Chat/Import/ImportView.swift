import SwiftUI

struct ImportView: View {

    @EnvironmentObject var presenter: ImportPresenter

    var body: some View {
        VStack(spacing: 8.0) {
            Image("profile_icon")
                .resizable()
                .frame(width: 128, height: 128)
                .padding(.top, 24.0)

            TextFieldView(title: "Private key", placeholder: "4dc0055d1831…", input: $presenter.input)

            Spacer()

            BrandButton(title: "Ok, done" ) {
                try await presenter.didPressImport()
            }
            .padding(16.0)
        }
    }
}

#if DEBUG
struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView()
    }
}
#endif
