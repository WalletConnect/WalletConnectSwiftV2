import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var viewModel: SettingsPresenter

    @State private var copyAlert: Bool = false

    var body: some View {
        List {
            Section(header: Text("Account")) {
                row(title: "CAIP-10", subtitle: viewModel.account)
                row(title: "Private key", subtitle: viewModel.privateKey)
            }

            Section(header: Text("Device")) {
                row(title: "Client ID", subtitle: viewModel.clientId)
                row(title: "Device Token", subtitle: viewModel.deviceToken)
            }
        }
        .listStyle(.insetGrouped)
        .alert("Value copied to clipboard", isPresented: $copyAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            viewModel.objectWillChange.send()
        }
    }

    func row(title: String, subtitle: String) -> some View {
        return Button(action: {
            UIPasteboard.general.string = subtitle
            copyAlert = true
        }) {
            HStack(spacing: 16) {
                VStack {
                    Text(title)
                    Spacer()
                }
                .padding(.vertical, 8.0)

                Text(subtitle)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.gray)
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
