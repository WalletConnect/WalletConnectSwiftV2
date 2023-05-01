import SwiftUI
import Web3Modal

struct AuthView: View {

    @ObservedObject var viewModel: AuthViewModel

    @State var showSheet: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            VStack(spacing: 16.0) {
                
                Spacer()
                
                Image(uiImage: viewModel.qrImage ?? UIImage())
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 300, height: 300)
                
                signingLabel()
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                connectWalletButton()
                
                Button("Copy URI", action: { viewModel.copyDidPressed() })
                    .buttonStyle(CircleButtonStyle())
                
                Button("Deeplink", action: { viewModel.deeplinkPressed() })
                    .buttonStyle(CircleButtonStyle())
                
                
            }
            .padding(16.0)
            
            
            if showSheet {
                Web3ModalSheet()
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut)
            }
        }
        .onAppear { Task(priority: .userInitiated) {
            try await viewModel.setupInitialState()
        }}
    }

    private func connectWalletButton() -> some View {
        
        Button("Connect Wallet", action: { showSheet.toggle() })
            .buttonStyle(CircleButtonStyle())
    }
    
    @ViewBuilder
    private func signingLabel() -> some View {
        switch viewModel.state {
        case .error(let error):
            SigningLabel(state: .error(error.localizedDescription))
                .frame(height: 50)
        case .signed:
            SigningLabel(state: .signed)
                .frame(height: 50)
        case .none:
            Spacer().frame(height: 50)
        }
    }
}

struct SigningLabel: View {
    enum State {
        case signed
        case error(String)

        var color: Color {
            switch self {
            case .signed: return .green.opacity(0.6)
            case .error: return .red.opacity(0.6)
            }
        }

        var text: String {
            switch self {
            case .signed:
                return "Authenticated"
            case .error:
                return "Authenticion error"
            }
        }
    }

    let state: State

    var body: some View {
        VStack {
            Text(state.text)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .padding(16.0)
        }
        .fixedSize(horizontal: true, vertical: false)
        .background(state.color)
        .cornerRadius(4.0)
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
