import SwiftUI

struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var presenter: WelcomePresenter

    @State private var importAlert: Bool = false

    var body: some View {
        ZStack {
            Color.grey100
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Image((colorScheme == .light) ? "welcome-light" : "welcome-dark")
                    .scaledToFill()
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                Text("Welcome")
                    .foregroundColor(.grey8)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                
                Text("We made this Example Wallet App to help developers integrate the WalletConnect SDK and provide an amazing experience to their users.")
                    .foregroundColor(.grey50)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 10)
                
                Spacer()

                button(title: "Import", action: { importAlert = true })

                button(title: "Create new account", action: { presenter.onGetStarted() })
            }
            .padding([.horizontal, .vertical], 20)
            .padding(.top, 20)
        }
        .ignoresSafeArea(.keyboard)
        .alert("Import account", isPresented: $importAlert) {
            TextField("Private key", text: $presenter.input)
                .textInputAutocapitalization(.never)
            Button("OK", action: presenter.onImport)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enter account private key")
        }
    }

    func button(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .blue100,
                            .blue200
                        ]),
                        startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(20)
        }
        .padding(.top, 16)
        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
#endif
