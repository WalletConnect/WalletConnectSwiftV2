import SwiftUI
import AsyncButton
import Web3ModalUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsPresenter
    @State private var copyAlert: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                separator()

                Group {
                    header(title: "Account")
                    row(title: "CAIP-10", subtitle: viewModel.account)
                    row(title: "Smart Account", subtitle: viewModel.smartAccount)
                    row(title: "Private key", subtitle: viewModel.privateKey)
                }
                .padding(.horizontal, 20)

                separator()

                Group {
                    header(title: "Device")
                    row(title: "Client ID", subtitle: viewModel.clientId)
                    row(title: "Device Token", subtitle: viewModel.deviceToken)
                }
                .padding(.horizontal, 20)

                separator()

                Group {
                    Button {
                        viewModel.browserPressed()
                    } label: {
                        Text("Browser")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 44.0)
                    
                    AsyncButton {
                        try await sendTransaction()
                    } label: {
                        Text("Send Transaction")
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 44.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.m)
                            .stroke(Color.green, lineWidth: 1)
                    )
                    .padding(.bottom, 24)

                    AsyncButton {
                        try await viewModel.logoutPressed()
                    } label: {
                        Text("Log out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 44.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.m)
                            .stroke(Color.red, lineWidth: 1)
                    )
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .alert("Value copied to clipboard", isPresented: $copyAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            viewModel.objectWillChange.send()
        }
    }
    
    @discardableResult
    func sendTransaction() async throws -> String {
        let client = await SmartAccount.instance.getClient()
        return try await client.sendTransaction(.init(
            to: "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
            value: "0",
            data: "0x68656c6c6f"
        ))
    }

    func header(title: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.Foreground100)
                .font(.large700)
                .padding(.vertical, 6)
            Spacer()
        }
    }

    func row(title: String, subtitle: String) -> some View {
        return Button(action: {
            UIPasteboard.general.string = subtitle
            copyAlert = true
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(title)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.Foreground100)
                        .font(.paragraph700)

                    Image("copy_small")
                        .foregroundColor(.Foreground100)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)

                Text(subtitle)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.Foreground150)
                    .font(.paragraph500)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
            .background(Color.Foreground100.opacity(0.05).cornerRadius(12))
        }
        .frame(maxWidth: .infinity)
    }

    func separator() -> some View {
        Rectangle()
            .foregroundColor(.Foreground100.opacity(0.05))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .padding(.top, 8)
    }
}
