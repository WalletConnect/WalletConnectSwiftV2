import SwiftUI

struct AuthView: View {

    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 16.0) {

            Spacer()

            Image(uiImage: viewModel.qrImage ?? UIImage())
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 300, height: 300)

            Spacer()

            Button("Connect Wallet", action: { })
                .buttonStyle(CircleButtonStyle())

            Button("Copy URI", action: { viewModel.copyDidPressed() })
                .buttonStyle(CircleButtonStyle())
        }
        .padding(16.0)
        .onAppear { Task(priority: .userInitiated) {
            try await viewModel.setupInitialState()
        }}
    }
}

struct CircleButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: 200, height: 44)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.blue.opacity(0.5) : Color.blue)
            .font(.system(size: 17, weight: .semibold))
            .cornerRadius(8.0)
    }
}

